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
      helpers = pkgs: import ./checks { inherit pkgs; };
    in
    {
      formatter = eachSystem (system: (helpers pkgsFor.${system}).formatter);

      checks = eachSystem (system: (helpers pkgsFor.${system}).checks);

      packages = eachSystem (system: {
        options-doc = (helpers pkgsFor.${system}).optionsDoc.optionsCommonMark;
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
            ];
          };
        }
      );
    };
}
