{
  description = "Build dependencies via Nix";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem
    (
      system: let
        name = "datadrivers-demo-app";
        version = self.shortRev or self.dirtyShortRev or self.lastModified or "dirty";
        pkgs = import nixpkgs {
          system = system;
          config.allowUnfreePredicate = pkg:
            builtins.elem (pkgs.lib.getName pkg) [
              "terraform"
            ];
        };
        local_ci = pkgs.writeScriptBin "ci-local" ''
          DEPLOY=0
          GITHUB_STEP_SUMMARY="$GITHUB_STEP_SUMMARY"
          while getopts "ds:" flag
          do
              case $flag in
              d)    echo "Deploy mode"
                    DEPLOY=1
                    ;;
              s)    STAGE=$OPTARG
                    echo "Using Stage: $STAGE"
                    ;;
              esac
          done
          set -euo pipefail
          export TF_VAR_stage=$STAGE

          echo  -e "\e[1;34mTerraform Plan\e[0m"
          (
            cd terraform
            terraform init -backend-config="key=tfstate-$STAGE"
            terraform plan
          )

          if [ $DEPLOY -eq 1 ]
          then
            echo  -e "\e[1;34mTerraform Apply\e[0m"
            (
              cd terraform
              terraform apply -auto-approve
            )
          fi
          echo  -e "\e[1;34mBuild Docker Image\e[0m"
          (
            ECR_REPOSITORY=$(cd terraform; terraform output -raw repository_url)
            nix build .#docker
            line=$(docker load -i result | tee >(grep -e '/^Loaded image:/s'))
            echo $line 
            name=$(echo $line|sed -n '/^Loaded image:/s/^Loaded image: \(.*\)$/\1/p')
            if [ $DEPLOY -eq 1 ]
            then
              ECR_REPOSITORY=$(cd terraform; terraform output -raw repository_url)
              echo  -e "\e[1;34mLog into ECR \e[0m"
              (
                cd terraform
                aws ecr get-login-password --region $(terraform output -raw region) | docker login --username AWS --password-stdin $(terraform output -raw repository_url)

              )
              echo  -e "\e[1;34mPush Docker Image\e[0m"
              docker image tag $name $ECR_REPOSITORY:$STAGE
              docker push $ECR_REPOSITORY:$STAGE
            fi
          )

          if [ $DEPLOY -eq 1 ]
          then
            echo  -e "\e[1;34mK8s login\e[0m"
            (
              cd terraform; aws eks --region $(terraform output -raw region) update-kubeconfig   --name $(terraform output -raw cluster_name)
            )
            ECR_REPOSITORY=$(cd terraform; terraform output -raw repository_url)
            export IMAGE=$ECR_REPOSITORY:$STAGE
            echo  -e "\e[1;34mK8s Apply App Resources\e[0m"
            for file in k8s/*.yaml
            do 
              envsubst < $file | kubectl apply -f -
            done
            kubectl wait  -n datadrivers-demo --for=jsonpath='{.status.loadBalancer.ingress[0].hostname}' service/datadrivers-demo-lb
            endpoint=$(kubectl get services -n datadrivers-demo datadrivers-demo-lb --output jsonpath='{.status.loadBalancer.ingress[0].hostname}')
            echo App Endpoint: $endpoint
            if [ -n "$GITHUB_STEP_SUMMARY" ]
            then
              echo  -e "\e[1;34mSummary\e[0m"
              echo "# Build Summary " >> $GITHUB_STEP_SUMMARY
              echo "App endpoint: [$endpoint](http://$endpoint)" >> $GITHUB_STEP_SUMMARY
            fi
          fi
        '';
      in {
        devShells.default = pkgs.mkShell {
          buildInputs =
            [local_ci]
            ++ (with pkgs; [
              awscli2
              envsubst
              k9s
              kubectl
              nodejs_23
              podman
              terraform
            ]);
          shellHook = ''
            echo "Nix flake revision is ${version}"
            echo "nixpkgs revision is ${nixpkgs.rev}"
          '';
        };
        formatter = nixpkgs.legacyPackages.x86_64-linux.alejandra;
        packages = {
          default = pkgs.buildNpmPackage {
            inherit name;

            buildInputs = with pkgs; [
              nodejs_23
            ];

            src = ./app;

            npmDepsHash = "sha256-HjZYtUGxEzG7DsmrTCaT3kh7QzcWgEMPAXGQZuU/3cs=";

            dontNpmBuild = true;

            installPhase = ''
              mkdir -p $out/dist
              cp -r * $out/dist
              makeWrapper ${pkgs.lib.getExe pkgs.nodejs_23} $out/bin/${name} --add-flags $out/dist/
            '';
          };

          docker = let
            bin = "${self.packages.${system}.default}/bin/${name}";
          in
            pkgs.dockerTools.buildLayeredImage {
              inherit name;
              tag = version;

              config = {
                Entrypoint = [bin];
                ExposedPorts."8000/tcp" = {};
              };
            };
        };
      }
    );
}
