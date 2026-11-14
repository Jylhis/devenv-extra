{ pkgs
, lib
, config
, ...
}:
let
  cfg = config.languages.qml;
  qs = cfg.quickshell;
  qmlDir = "lib/qt-6/qml";
  aliasDir = "$DEVENV_STATE/qml/modules";
in
{
  options.languages.qml = {
    enable = lib.mkEnableOption "tools for QML development";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.qt6.qtdeclarative;
      defaultText = lib.literalExpression "pkgs.qt6.qtdeclarative";
      description = "The Qt QML package: Qt's QML modules, qmllint and qmlformat.";
    };

    lsp = {
      enable = lib.mkEnableOption "QML Language Server" // {
        default = true;
      };
      package = lib.mkOption {
        type = lib.types.package;
        default = cfg.package;
        defaultText = lib.literalExpression "config.languages.qml.package";
        description = "The package that provides qmlls.";
      };
    };

    importPaths = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      example = lib.literalExpression "[ pkgs.qt6.qt5compat ]";
      description = "Extra QML module packages. Each adds its `${qmlDir}` to `QML_IMPORT_PATH`.";
    };

    quickshell = {
      enable = lib.mkEnableOption "Quickshell configuration development";

      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.quickshell;
        defaultText = lib.literalExpression "pkgs.quickshell";
        description = "The Quickshell package. Its QML modules join `QML_IMPORT_PATH`.";
      };

      configDir = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "shell";
        description = ''
          Quickshell configuration root, relative to `DEVENV_ROOT`.
          When set, the shell links it as the `qs` module under
          `$DEVENV_STATE/qml/modules` and adds that directory to `QML_IMPORT_PATH`,
          so `import qs.*` resolves in qmlls and qmllint.
        '';
      };

      run = {
        enable = lib.mkEnableOption "a `quickshell -p` development process";
        env = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = { };
          example = {
            TZDIR = "/etc/zoneinfo";
          };
          description = "Environment variables set on the `quickshell` process.";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !(qs.enable && qs.run.enable) || qs.configDir != null;
        message =
          "languages.qml.quickshell.run.enable requires "
          + "languages.qml.quickshell.configDir.";
      }
    ];

    packages = lib.unique (
      [ cfg.package ]
      ++ lib.optional cfg.lsp.enable cfg.lsp.package
      ++ lib.optional qs.enable qs.package
    );

    env.QML_IMPORT_PATH = lib.makeSearchPath qmlDir (
      lib.optional qs.enable qs.package ++ [ cfg.package ] ++ cfg.importPaths
    );

    enterShell = lib.mkIf (qs.enable && qs.configDir != null) ''
      mkdir -p "${aliasDir}"
      ln -sfn "$DEVENV_ROOT/${qs.configDir}" "${aliasDir}/qs"
      export QML_IMPORT_PATH="${aliasDir}:$QML_IMPORT_PATH"
    '';

    processes.quickshell = lib.mkIf (qs.enable && qs.run.enable) {
      exec =
        lib.concatStrings (lib.mapAttrsToList (n: v: "${n}=${lib.escapeShellArg v} ") qs.run.env)
        + "exec ${lib.getExe' qs.package "quickshell"} "
        + "-p \"$DEVENV_ROOT/${toString qs.configDir}\"";
    };
  };
}
