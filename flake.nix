{
  description = "Build dependencies via Nix";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem
    (
      system: let
        pkgs = import nixpkgs {
          system = system;
          config.allowUnfreePredicate = pkg:
            builtins.elem (pkgs.lib.getName pkg) [
              "terraform"
            ];
        };
      in {
        devShells.default = import ./shell.nix {inherit pkgs;};
        formatter = nixpkgs.legacyPackages.x86_64-linux.alejandra;
      }
    );
}
