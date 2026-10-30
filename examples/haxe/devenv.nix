{ pkgs, ... }:
{
  languages.haxe = {
    enable = true;
    libraries = with pkgs.haxePackages; [ format ];
  };
}
