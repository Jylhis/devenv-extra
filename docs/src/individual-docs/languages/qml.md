Provides Qt's QML tools (`qmlls`, `qmllint` and `qmlformat`) from `qt6.qtdeclarative`, and sets
`QML_IMPORT_PATH` so they find Qt's QML modules. The language server is on by default; set
`lsp.enable = false` to skip it. `qmlls` and `qmllint` read the variable only with `-E`.

Add further QML module packages with `importPaths`; each contributes its `lib/qt-6/qml`
directory to `QML_IMPORT_PATH`:

```nix
languages.qml.importPaths = [ pkgs.qt6.qt5compat ];
```

## Quickshell

`quickshell.enable` adds [Quickshell](https://quickshell.org/) and its QML modules. Set
`quickshell.configDir` (relative to `DEVENV_ROOT`) and the shell links that directory as the `qs`
module, so `import qs.*` resolves in qmlls and qmllint. `quickshell.run.enable` adds a
`quickshell -p` process, and `quickshell.run.env` sets variables on it:

```nix
languages.qml = {
  enable = true;
  quickshell = {
    enable = true;
    configDir = "shell";
    run.enable = true;
  };
};
```

Quickshell is optional because it builds on Linux only.

[comment]: # (Please add your documentation on top of this line)

@AUTOGEN_OPTIONS@
