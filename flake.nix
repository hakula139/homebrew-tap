{
  description = "Homebrew tap development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    devkit = {
      url = "github:hakula139/devkit/v3";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      devkit,
      ...
    }:
    devkit.lib.eachSystem devkit.lib.systems (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        dk = devkit.lib.mkLib pkgs;
        preCommit = dk.preCommit {
          src = ./.;
          hooks = {
            nu-check.enable = true;
            prettier.enable = true;
            shellcheck.enable = true;
            shfmt.enable = true;
          };
        };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            dk.nushell
            dk.nu-test
          ];
          inputsFrom = [ preCommit ];
        };

        checks.tests = dk.nuTests { src = ./.; };

        formatter = pkgs.nixfmt-tree;
      }
    );
}
