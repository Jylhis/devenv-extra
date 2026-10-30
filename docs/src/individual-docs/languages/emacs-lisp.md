Provides Emacs, [Eask](https://emacs-eask.github.io/) and, by default, the
[ellsp](https://github.com/emacs-lsp/ellsp) language server for Emacs Lisp development.

`ellsp` is not in nixpkgs: it comes from [nixpkgs-extra](https://github.com/Jylhis/nixpkgs-extra),
so add that input with its `default` overlay to `devenv.yaml`. Set `lsp.enable = false` to
skip it. Elsa is not included because `emacsPackages.elsa` does not build on Emacs 31.

[comment]: # (Please add your documentation on top of this line)

@AUTOGEN_OPTIONS@
