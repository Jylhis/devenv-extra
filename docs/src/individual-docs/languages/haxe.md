Provides `haxe`, `haxelib` and `neko`. Libraries listed in `libraries` are merged into a single
read-only haxelib repository that `HAXELIB_PATH` points at, so nothing is fetched with
`haxelib install`.

`lime.enable` and `pkgs.haxePackages.hxcpp` 4.3.x need
[nixpkgs-extra](https://github.com/Jylhis/nixpkgs-extra) with its `default` and `overrides`
overlays applied.

[comment]: # (Please add your documentation on top of this line)

@AUTOGEN_OPTIONS@
