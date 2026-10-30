# Haxe toolchain; libraries come from Nix as one haxelib repository.
# lime, hxp and hxcpp 4.3.x come from nixpkgs-extra (default and overrides overlays).
{ pkgs, config, lib, ... }:
let
  cfg = config.languages.haxe;
  lime = pkgs.haxe-lime;

  # Only lime's bin/ goes on PATH. Haxelib derivations are kept out of `packages`: haxe's
  # setup hook would make HAXELIB_PATH a colon list, and nixpkgs' haxe wrapper then loses
  # the compiler exit status.
  limeBin = pkgs.runCommand "lime-bin-${lime.version}" { inherit (lime) meta; } ''
    mkdir -p $out/bin
    ln -s ${lime}/bin/lime $out/bin/lime
  '';

  selected = cfg.libraries ++ lib.optionals cfg.lime.enable ([ lime ] ++ lime.haxeDeps);
  repo = pkgs.buildEnv {
    name = "devenv-haxelib-repo";
    paths = lib.unique selected;
    pathsToLink = [ "/lib/haxe" ];
  };
in
{
  options.languages.haxe = {
    enable = lib.mkEnableOption "tools for Haxe development";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.haxe;
      defaultText = lib.literalExpression "pkgs.haxe";
      description = "The Haxe package to use.";
    };

    libraries = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      example = lib.literalExpression "with pkgs.haxePackages; [ format heaps ]";
      description = ''
        Haxe libraries (derivations with a lib/haxe haxelib layout, e.g. pkgs.haxePackages.*)
        merged into the single repository HAXELIB_PATH points at.
      '';
    };

    lime.enable = lib.mkEnableOption ''
      lime and the `lime` command (pkgs.haxe-lime from nixpkgs-extra, built from source;
      x86_64-linux only)
    '';
  };

  config = lib.mkIf cfg.enable {
    packages = [
      cfg.package
      pkgs.neko
    ] ++ lib.optional cfg.lime.enable limeBin;

    env = lib.optionalAttrs (selected != [ ]) {
      HAXELIB_PATH = "${repo}/lib/haxe";
    };
  };
}
