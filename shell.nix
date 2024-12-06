{pkgs ? import <nixpkgs> {}}:
with pkgs;
  mkShell {
    buildInputs = [
      awscli2
      envsubst
      k9s
      kubectl
      kubernetes-helm
      terraform
      nodejs_23
      podman
    ];

    shellHook = ''
    '';
  }
