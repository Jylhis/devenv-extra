# Formatter and checks, shared by every system.
{ pkgs, vanillaPkgs }:
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

  # A check that runs a linter over the source tree.
  srcCheck =
    name: tools: script:
    pkgs.runCommand name { nativeBuildInputs = tools; } ''
      cd ${src}
      ${script}
      touch $out
    '';

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

  # Modules whose base config still needs nixpkgs-extra. Keep in step with CONTRIBUTING.md and
  # drop an entry once its packages are in nixpkgs.
  vanillaAllowlist = {
    emacs-lisp = "the default language server, ellsp, is only in nixpkgs-extra";
  };

  # The base config (enable = true only) must evaluate against plain nixpkgs. A missing
  # package is not catchable by tryEval, so each module gets its own check.
  vanillaChecks = lib.listToAttrs (
    map (
      m:
      let
        inherit
          (lib.evalModules {
            modules = [
              stub
              m.file
              { _module.args.pkgs = vanillaPkgs; }
              (lib.setAttrByPath (m.optPath ++ [ "enable" ]) true)
            ];
          })
          config
          ;
        forced = builtins.deepSeq [
          (map (p: p.drvPath) config.packages)
          (lib.mapAttrs (_: toString) config.env)
          (lib.mapAttrs (_: p: p.exec) config.processes)
        ] true;
      in
      lib.nameValuePair "vanilla-${m.name}" (
        pkgs.runCommand "vanilla-${m.name}" { } ''
          ${lib.optionalString (!forced) "exit 1"}
          touch $out
        ''
      )
    ) (lib.filter (m: !vanillaAllowlist ? ${m.name}) modules)
  );

  perModuleChecks = evalChecks // vanillaChecks;

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

  checks = perModuleChecks // {
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

    vanilla-allowlist =
      let
        names = map (m: m.name) modules;
        unknown = lib.filter (n: !lib.elem n names) (lib.attrNames vanillaAllowlist);
      in
      problemsCheck "vanilla-allowlist" (map (n: "vanillaAllowlist: ${n} is not a module") unknown);

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

    markdownlint = srcCheck "markdownlint" [ pkgs.markdownlint-cli2 ] ''
      HOME=$TMPDIR markdownlint-cli2 "docs/**/*.md"
    '';

    editorconfig = srcCheck "editorconfig" [ pkgs.editorconfig-checker ] "editorconfig-checker";

    ast-grep = pkgs.runCommand "ast-grep" { nativeBuildInputs = [ pkgs.ast-grep ]; } ''
      cd ${src}
      ast-grep scan --error
      touch $out
    '';
  };
}
