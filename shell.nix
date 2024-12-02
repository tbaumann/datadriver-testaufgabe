{ pkgs ? import <nixpkgs> { } }:
with pkgs;
mkShell {
  buildInputs = [
    awscli2
    earthly
    envsubst
    k9s
    kubectl
    openssl
    terraform
  ];

  shellHook = ''
  '';
}
