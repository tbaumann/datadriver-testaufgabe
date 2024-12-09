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
          while getopts "ds:" flag
          do
              case $flag in
              d)    echo "Deploy mode"
                    DEPLOY=1
                    ;;
              s)    IMAGE_TAG=$OPTARG
                    echo "Using tag: $IMAGE_TAG"
                    ;;
              esac
          done
          set -euo pipefail

          echo  -e "\e[1;34mTerraform Plan\e[0m"
          (
            cd terraform
            terraform init
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
          echo  -e "\e[1;34mLog into ECR \e[0m"
          (
            cd terraform
            aws ecr get-login-password --region $(terraform output -raw region) | docker login --username AWS --password-stdin $(terraform output -raw repository_url)
          )
          echo  -e "\e[1;34mBuild Docker Image\e[0m"
          (
            ECR_REPOSITORY=$(cd terraform; terraform output -raw repository_url)
            cd app
            docker build -t $ECR_REPOSITORY:$IMAGE_TAG .
            echo  -e "\e[1;34mPush Docker Image\e[0m"
            if [ $DEPLOY -eq 1 ]
            then
              docker push $ECR_REPOSITORY:$IMAGE_TAG
            fi
          )

          if [ $DEPLOY -eq 1 ]
          then
            echo  -e "\e[1;34mK8s login\e[0m"
            (
              cd terraform; aws eks --region $(terraform output -raw region) update-kubeconfig   --name $(terraform output -raw cluster_name)
            )
            echo  -e "\e[1;34mK8s Apply App Resources\e[0m"
            (
              kubectl apply -f k8s/
              echo App Endpoint: http://$(kubectl get services -n datadrivers-demo datadrivers-demo-lb --output jsonpath='{.status.loadBalancer.ingress[0].hostname}')
            )
          fi
        '';
      in {
        devShells.default = pkgs.mkShell {
          buildInputs =
            [local_ci]
            ++ (with pkgs; [
              awscli2
              k9s
              kubectl
              terraform
              nodejs_23
              podman
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
