# Upstream option-style problems in the options declared under src/modules, as a list of strings.
{
  lib,
  options,
  modulesDir,
}:
let
  ours = lib.filter (
    o: lib.any (d: lib.hasPrefix (toString modulesDir) (toString d)) o.declarations
  ) (lib.collect lib.isOption options);

  forOption =
    o:
    let
      name = lib.showOption o.loc;
      description = o.description or null;
      enableText = "Whether to enable tools for .* development\\.";
      isLanguageEnable =
        lib.length o.loc == 3 && lib.head o.loc == "languages" && lib.last o.loc == "enable";
    in
    lib.optional (description == null) "${name}: no description"
    ++ lib.optional (
      o.type.name == "package" && !(o ? defaultText)
    ) "${name}: package option without defaultText"
    ++ lib.optional (
      isLanguageEnable && builtins.match enableText (toString description) == null
    ) "${name}: description must be mkEnableOption \"tools for <Name> development\"";

  forLsp =
    n: lsp:
    lib.optional (
      !(lsp ? enable) || (lsp.enable.default or false) != true
    ) "languages.${n}.lsp.enable: must default to true"
    ++ lib.optional (!(lsp ? package)) "languages.${n}.lsp.package: missing";
in
lib.concatMap forOption ours
++ lib.concatLists (
  lib.mapAttrsToList (n: o: lib.optionals (o ? lsp) (forLsp n o.lsp)) (options.languages or { })
)
