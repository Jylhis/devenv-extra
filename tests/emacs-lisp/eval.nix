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
        ../../src/modules/languages/emacs-lisp.nix
        { _module.args = { inherit pkgs; }; }
        { languages.emacs-lisp = settings; }
      ];
    }).config;

  off = evalWith { };
  base = evalWith { enable = true; };
  bare = evalWith {
    enable = true;
    lsp.enable = false;
  };
in
assert off.packages == [ ];
assert lib.length base.packages == 3; # emacs-nox + eask-cli + ellsp
assert lib.length bare.packages == 2; # emacs-nox + eask-cli
true
