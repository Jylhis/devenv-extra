# Formatter and checks, shared by every system.
{ pkgs }:
let
  inherit (pkgs) lib;
  src = ../.;
  modulesDir = ../src/modules;
  stub = ./stub.nix;

  formatter = pkgs.treefmt.withConfig {
    runtimeInputs = [
      pkgs.nixpkgs-fmt
      pkgs.nixfmt
    ];
    settings = {
      on-unmatched = "info";
      tree-root-file = "flake.nix";
      formatter.nixpkgs-fmt = {
        command = "nixpkgs-fmt";
        includes = [ "src/modules/**/*.nix" ];
      };
      formatter.nixfmt = {
        command = "nixfmt";
        includes = [ "*.nix" ];
        excludes = [ "src/modules/**/*.nix" ];
      };
    };
  };

  testNames = lib.optionals (builtins.pathExists ../tests) (
    lib.attrNames (
      lib.filterAttrs (n: t: t == "directory" && builtins.pathExists (../tests + "/${n}/eval.nix")) (
        builtins.readDir ../tests
      )
    )
  );

  evalChecks = lib.listToAttrs (
    map (
      n:
      let
        result = import (../tests + "/${n}/eval.nix") {
          inherit pkgs stub;
          inherit (pkgs) lib;
        };
      in
      lib.nameValuePair "eval-${n}" (
        pkgs.runCommand "eval-${n}" { } ''
          ${lib.optionalString (result != true) "echo 'eval test did not return true' >&2; exit 1"}
          touch $out
        ''
      )
    ) testNames
  );

  moduleFiles = lib.optionals (builtins.pathExists modulesDir) (
    lib.filter (f: lib.hasSuffix ".nix" (toString f)) (lib.filesystem.listFilesRecursive modulesDir)
  );

  evaluated = lib.evalModules {
    modules = [
      stub
      {
        _module.args.pkgs = pkgs;
        _module.check = false;
      }
    ]
    ++ moduleFiles;
  };

  # Document only options declared under src/modules, not the stub's.
  optionsDoc = pkgs.nixosOptionsDoc {
    inherit (evaluated) options;
    warningsAreErrors = true;
    transformOptions =
      o:
      o
      // {
        visible = o.visible && lib.any (d: lib.hasPrefix (toString modulesDir) (toString d)) o.declarations;
      };
  };
in
{
  inherit formatter optionsDoc;

  checks = evalChecks // {
    options-doc = optionsDoc.optionsCommonMark;

    format = pkgs.runCommand "format" { nativeBuildInputs = [ formatter ]; } ''
      cp -r ${src} source
      chmod -R +w source
      cd source
      HOME=$TMPDIR treefmt --no-cache --fail-on-change
      touch $out
    '';

    ast-grep = pkgs.runCommand "ast-grep" { nativeBuildInputs = [ pkgs.ast-grep ]; } ''
      cd ${src}
      ast-grep scan --error
      touch $out
    '';
  };
}
