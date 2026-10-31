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

  # Every module, with the option path its enable flag lives under.
  modules =
    lib.concatMap
      (
        kind:
        let
          dir = modulesDir + "/${kind}";
          isNix = f: t: t == "regular" && lib.hasSuffix ".nix" f;
          files = lib.filterAttrs isNix (builtins.readDir dir);
        in
        lib.optionals (builtins.pathExists dir) (
          lib.mapAttrsToList (
            f: _:
            let
              name = lib.removeSuffix ".nix" f;
            in
            {
              inherit kind name;
              file = dir + "/${f}";
              optPath =
                if kind == "languages" then
                  [
                    "languages"
                    name
                  ]
                else
                  [ name ];
            }
          ) files
        )
      )
      [
        "languages"
        "integrations"
      ];

  moduleFiles = map (m: m.file) modules;

  # A check that prints every problem at once, rather than stopping at the first throw.
  problemsCheck =
    name: problems:
    pkgs.runCommand name { } ''
      ${lib.optionalString (problems != [ ]) ''
        printf '%s\n' ${lib.escapeShellArgs problems} >&2
        exit 1
      ''}
      touch $out
    '';

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

    layout = problemsCheck "layout" (
      import ./layout.nix {
        inherit lib modules;
        root = src;
      }
    );

    option-style = problemsCheck "option-style" (
      import ./option-style.nix {
        inherit lib modulesDir;
        inherit (evaluated) options;
      }
    );

    # Importing every module and enabling nothing must leave the shell untouched.
    defaults-off =
      let
        inherit (evaluated) config;
        names = attrs: toString (lib.attrNames attrs);
        packageNames = toString (map lib.getName config.packages);
      in
      problemsCheck "defaults-off" (
        lib.optional (config.packages != [ ]) "packages: ${packageNames}"
        ++ lib.optional (config.env != { }) "env: ${names config.env}"
        ++ lib.optional (config.processes != { }) "processes: ${names config.processes}"
        ++ lib.optional (config.enterShell != "") "enterShell is not empty"
        ++ lib.optional (config.claude.code.mcpServers != { }) "claude.code.mcpServers is not empty"
      );

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
