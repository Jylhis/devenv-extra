# Problems with the per-module file layout (see CONTRIBUTING.md), as a list of strings.
{
  lib,
  root,
  modules,
}:
let
  exists = p: builtins.pathExists (root + "/${p}");
  read = p: builtins.readFile (root + "/${p}");
  entries = d: lib.optionalAttrs (exists d) (builtins.readDir (root + "/${d}"));

  languagesDocs = "docs/src/individual-docs/languages";
  integrationsDocs = "docs/src/content/docs/integrations";
  docPage =
    m:
    if m.kind == "languages" then
      "${languagesDocs}/${m.name}.md"
    else
      "${integrationsDocs}/${m.name}.md";
  # Upstream's marker, verbatim from cachix/devenv's language pages.
  marker = ''
    [comment]: # (Please add your documentation on top of this line)

    @AUTOGEN_OPTIONS@
  '';

  required = m: [
    "${m.name}/devenv.nix"
    "${m.name}/devenv.yaml"
    "tests/${m.name}/devenv.nix"
    "tests/${m.name}/devenv.yaml"
    "tests/${m.name}/eval.nix"
    "examples/${m.name}/devenv.nix"
    (docPage m)
  ];

  forModule =
    m:
    let
      page = docPage m;
      test = "tests/${m.name}/devenv.nix";
    in
    map (p: "${m.name}: missing ${p}") (lib.filter (p: !exists p) (required m))
    ++ lib.optional (
      m.kind == "languages" && exists page && !lib.hasSuffix marker (read page)
    ) "${m.name}: ${page} must end with the upstream marker lines"
    ++ lib.optional (
      exists test && !lib.hasInfix "enterTest" (read test)
    ) "${m.name}: ${test} has no enterTest";

  namesOf = kind: map (m: m.name) (lib.filter (m: kind == null || m.kind == kind) modules);
  subdirs = d: lib.attrNames (lib.filterAttrs (_: t: t == "directory") (entries d));
  pages =
    d:
    map (lib.removeSuffix ".md") (
      lib.filter (lib.hasSuffix ".md") (
        lib.attrNames (lib.filterAttrs (_: t: t == "regular") (entries d))
      )
    );
  orphans =
    what: found: known:
    map (n: "${what}/${n} has no module") (lib.filter (n: !lib.elem n known) found);
in
lib.concatMap forModule modules
++ orphans "tests" (subdirs "tests") (namesOf null)
++ orphans "examples" (subdirs "examples") (namesOf null)
++ orphans languagesDocs (pages languagesDocs) (namesOf "languages")
++ orphans integrationsDocs (pages integrationsDocs) (namesOf "integrations")
