# AGENTS.md

Reusable devenv modules, laid out like cachix/devenv so each can be upstreamed.
[CONTRIBUTING.md](CONTRIBUTING.md) lists the upstream rules and the check enforcing each.

## Layout

- `src/modules/languages/<name>.nix`, `src/modules/integrations/<name>.nix`: the modules.
- `<name>/devenv.nix` + `<name>/devenv.yaml`: thin import dir (`imports` the module; the
  yaml declares nixpkgs-extra for local-path imports).
- `tests/<name>/devenv.nix` + `devenv.yaml`: upstream-style smoke test (`enterTest`).
- `tests/<name>/eval.nix`: pure eval test, `{ pkgs, lib, stub }` returning `true`.
- `checks/stub.nix`: minimal stand-ins for the devenv options modules set.
- `checks/default.nix`: formatter and flake checks.
- `examples/<name>/`: a consumer through the `devenv-extra` input.
- `docs/src/individual-docs/languages/<name>.md`, `docs/src/content/docs/integrations/<name>.md`.
- `rules/` + `sgconfig.yml`: ast-grep rules.

## Commands

```bash
nix fmt
nix flake check -L
nix build .#options-doc
nix flake check --override-input nixpkgs-extra path:../nixpkgs-extra
cd tests/<name> && devenv test
nix run .#check-commits -- origin/main..HEAD
```

## Conventions

- Everything defaults off; importing a module changes nothing until enabled.
- Format `src/modules/**/*.nix` with nixpkgs-fmt, all other Nix with nixfmt (`nix fmt`
  does both). Lines are at most 100 characters.
- Follow devenv upstream option style: `lib.mkEnableOption`, package options via
  `lib.mkOption` with `defaultText` (never `mkPackageOption`), every option described,
  `config = lib.mkIf cfg.enable { ... }`. Language servers use
  `lsp.enable = lib.mkEnableOption "<X> Language Server" // { default = true; }` and
  `lsp.package`.
- Generic by default: no home paths, hostnames, private repo names or secrets.
- Packages missing from nixpkgs belong in nixpkgs-extra, never vendored here.
- The base config (`enable = true` only) must evaluate against plain nixpkgs (`vanilla-<name>`
  check); optional features may need nixpkgs-extra if the docs say so.
- Tests are pure eval against the stub (no builds); extend the stub only when needed.
- Docs: language pages end with `[comment]: # (Please add your documentation on top of this
  line)`, a blank line and `@AUTOGEN_OPTIONS@`, as upstream; keep docs in step with the options.
- One module or feature per commit, touching only its own files, so it cherry-picks into
  cachix/devenv. `check-commits` enforces this and the subject format.
- Commit subjects follow Conventional Commits (`feat(languages): add haxe`), with a short
  body saying why.
