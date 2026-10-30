{ pkgs, lib, config, ... }:
let
  cfg = config.languages.emacs-lisp;
in
{
  options.languages.emacs-lisp = {
    enable = lib.mkEnableOption "tools for Emacs Lisp development";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.emacs-nox;
      defaultText = lib.literalExpression "pkgs.emacs-nox";
      example = lib.literalExpression "pkgs.emacs";
      description = "The Emacs package to use.";
    };

    lsp = {
      enable = lib.mkEnableOption "Emacs Lisp Language Server" // { default = true; };
      # The server must run on the same Emacs as the shell's.
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.ellsp.override { emacs = cfg.package; };
        defaultText = lib.literalExpression "pkgs.ellsp.override { emacs = cfg.package; }";
        description = "The ellsp package to use.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    packages = [ cfg.package pkgs.eask-cli ]
      ++ lib.optional cfg.lsp.enable cfg.lsp.package;
  };
}
