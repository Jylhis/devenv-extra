{
  description = "Reusable devenv modules, laid out like cachix/devenv";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-extra = {
      url = "github:Jylhis/nixpkgs-extra";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-extra,
    }:
    let
      inherit (nixpkgs) lib;
      eachSystem = lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
      ];
      pkgsFor = eachSystem (
        system:
        import nixpkgs {
          inherit system;
          overlays = [
            nixpkgs-extra.overlays.default
            nixpkgs-extra.overlays.overrides
          ];
        }
      );
      helpers =
        system:
        import ./checks {
          pkgs = pkgsFor.${system};
          # Plain nixpkgs, as upstream devenv sees it.
          vanillaPkgs = nixpkgs.legacyPackages.${system};
        };
    in
    {
      formatter = eachSystem (system: (helpers system).formatter);

      checks = eachSystem (
        system: (helpers system).checks // { inherit (self.packages.${system}) check-commits; }
      );

      packages = eachSystem (system: {
        options-doc = (helpers system).optionsDoc.optionsCommonMark;
        check-commits = pkgsFor.${system}.callPackage ./tools/check-commits/package.nix { };
      });

      devShells = eachSystem (
        system:
        let
          pkgs = pkgsFor.${system};
        in
        {
          default = pkgs.mkShellNoCC {
            packages = [
              pkgs.nixpkgs-fmt
              pkgs.nixfmt
              self.formatter.${system}
              pkgs.ast-grep
              pkgs.devenv
              pkgs.go
            ];
          };
        }
      );
    };
}
