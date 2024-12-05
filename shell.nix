{pkgs ? import <nixpkgs> {}}:
with pkgs;
  mkShell {
    buildInputs = [
      awscli2
      envsubst
      k9s
      kubectl
      terraform
      nodejs_23
      podman
    ];

    shellHook = ''
    '';
  }
