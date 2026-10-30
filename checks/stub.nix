# Stand-ins for the devenv options the modules set, so tests/*/eval.nix can
# evaluate a module without devenv itself.
{ lib, ... }:
{
  options = {
    packages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
    };
    env = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
    };
    enterShell = lib.mkOption {
      type = lib.types.lines;
      default = "";
    };
    processes = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule { options.exec = lib.mkOption { type = lib.types.str; }; }
      );
      default = { };
    };
    claude.code = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      settingsPath = lib.mkOption {
        type = lib.types.str;
        default = ".claude/settings.json";
      };
      mcpServers = lib.mkOption {
        type = lib.types.attrsOf (lib.types.attrsOf lib.types.anything);
        default = { };
      };
    };
  };
}
