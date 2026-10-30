{
  languages.emacs-lisp.enable = true;

  enterTest = ''
    emacs --version
    command -v ellsp
  '';
}
