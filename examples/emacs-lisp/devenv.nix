{ pkgs, ... }:
{
  languages.emacs-lisp = {
    enable = true;
    package = pkgs.emacs;
    lsp.enable = true;
  };
}
