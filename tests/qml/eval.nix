# Pure eval test: defaults off, base, importPaths, Quickshell alias and process, assertion.
{
  pkgs,
  lib,
  stub,
}:
let
  evalWith =
    settings:
    (lib.evalModules {
      modules = [
        stub
        ../../src/modules/languages/qml.nix
        { _module.args = { inherit pkgs; }; }
        { languages.qml = settings; }
      ];
    }).config;

  names = cfg: map lib.getName cfg.packages;
  failed = cfg: lib.filter (a: !a.assertion) cfg.assertions;
  firstPath = cfg: lib.head (lib.splitString ":" cfg.env.QML_IMPORT_PATH);

  off = evalWith { };
  base = evalWith { enable = true; };
  noLsp = evalWith {
    enable = true;
    lsp.enable = false;
    importPaths = [ pkgs.hello ];
  };
  qs = evalWith {
    enable = true;
    quickshell.enable = true;
  };
  linked = evalWith {
    enable = true;
    quickshell = {
      enable = true;
      configDir = "shell";
    };
  };
  run = evalWith {
    enable = true;
    quickshell = {
      enable = true;
      configDir = "shell";
      run = {
        enable = true;
        env.TZDIR = "/etc/zoneinfo";
      };
    };
  };
  runNoDir = evalWith {
    enable = true;
    quickshell = {
      enable = true;
      run.enable = true;
    };
  };
in
assert off.packages == [ ] && off.env == { } && off.processes == { };
assert names base == [ "qtdeclarative" ];
assert lib.hasSuffix "/lib/qt-6/qml" base.env.QML_IMPORT_PATH;
assert base.enterShell == "" && base.processes == { } && failed base == [ ];
assert lib.hasInfix "hello" noLsp.env.QML_IMPORT_PATH;
assert names noLsp == [ "qtdeclarative" ];
assert lib.elem "quickshell" (names qs);
assert lib.hasInfix "quickshell" (firstPath qs);
assert qs.enterShell == "";
assert lib.hasInfix "ln -sfn \"$DEVENV_ROOT/shell\"" linked.enterShell;
assert lib.hasInfix "$DEVENV_STATE/qml/modules/qs" linked.enterShell;
assert lib.hasInfix "quickshell -p" run.processes.quickshell.exec;
assert lib.hasInfix "TZDIR=" run.processes.quickshell.exec;
assert failed run == [ ];
assert failed runNoDir != [ ];
true
