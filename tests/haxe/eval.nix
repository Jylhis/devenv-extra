# Pure eval test: defaults off, base, libraries, lime.
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
        ../../src/modules/languages/haxe.nix
        { _module.args = { inherit pkgs; }; }
        { languages.haxe = settings; }
      ];
    }).config;

  names = cfg: map lib.getName cfg.packages;

  off = evalWith { };
  base = evalWith { enable = true; };
  libs = evalWith {
    enable = true;
    libraries = [ pkgs.haxePackages.format ];
  };
  lime = evalWith {
    enable = true;
    lime.enable = true;
  };
in
assert off.packages == [ ] && off.env == { };
assert
  names base == [
    "haxe"
    "neko"
  ];
# No library selected: haxelib keeps its own (user) repository.
assert base.env == { };
assert lib.hasSuffix "/lib/haxe" libs.env.HAXELIB_PATH;
assert lib.elem "lime-bin" (names lime);
assert lime.env ? HAXELIB_PATH;
true
