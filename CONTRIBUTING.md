# Contributing

Every module here is meant to cherry-pick into [cachix/devenv](https://github.com/cachix/devenv).
This page lists the upstream rules that matter for that, and which check enforces each one.

## Rules

Upstream sources:

- [contributing]: `docs/src/content/docs/community/contributing.md`
- [create-language] and [create-service]: upstream's agent skills for new modules
- [devenv.nix]: upstream's git-hooks (formatters, markdownlint)

| # | Rule | Source | Enforced by |
|---|---|---|---|
| 1 | A new feature ships with docs and a test | [contributing] | `layout` |
| 2 | Language docs live at `docs/src/individual-docs/languages/<n>.md` and end with the marker lines below | [create-language] | `layout` |
| 3 | The base config (`enable = true` only) evaluates against plain nixpkgs | upstream has no nixpkgs-extra | `vanilla-<n>` |
| 4 | nixpkgs-fmt for `src/modules/**`, nixfmt for all other Nix | [devenv.nix] | `format` |
| 5 | Option style (see below) | [create-language] | `option-style`, `ast-grep`, `options-doc` |
| 6 | Importing a module changes nothing until it is enabled | [create-language] | `defaults-off` |
| 7 | Tests: `tests/<n>/devenv.nix` with `enterTest` | [create-language] | `layout`, CI `devenv` job |
| 8 | markdownlint (MD013 at 120, MD033 and MD034 off) and editorconfig | [devenv.nix] | `markdownlint`, `editorconfig` |
| 9 | Conventional Commits, one module per commit touching only its own files | this repo | `check-commits` |
| 10 | Generic: no home paths, hostnames or secrets | this repo | `ast-grep` (`no-home-paths`) |
| 11 | Services: no hardcoded ports, state under `DEVENV_STATE`/`DEVENV_RUNTIME` | [create-service] | documented only |
| 12 | Behaviour or breaking changes to an existing module add a `changelogs` entry | [contributing] | documented only |

The language docs marker, verbatim:

```markdown
[comment]: # (Please add your documentation on top of this line)

@AUTOGEN_OPTIONS@
```

Option style:

- `enable = lib.mkEnableOption "tools for <Name> development"` for languages;
- package options use `lib.mkOption` with `defaultText`, never `mkPackageOption`;
- every option has a description;
- `config = lib.mkIf cfg.enable { ... }`;
- language servers: `lsp.enable = lib.mkEnableOption "<X> Language Server" // { default = true; }`
  plus `lsp.package`.

Platforms: upstream CI also runs on aarch64-darwin. A feature that only works on some systems
needs `supported_systems` in its test's `.test-config.yml`, and the docs must say so.

## Known upstreaming blockers

The `vanilla-<n>` check skips modules listed in `vanillaAllowlist` in `checks/default.nix`:

| Module | Reason |
|---|---|
| emacs-lisp | The default language server, `ellsp`, is only in nixpkgs-extra |

Drop the entry once the package lands in nixpkgs. Optional features (for example `haxe.lime`)
may still need nixpkgs-extra; their docs must say so.

## Files per module

| File | Cherry-picks upstream |
|---|---|
| `src/modules/languages/<n>.nix` or `src/modules/integrations/<n>.nix` | yes |
| `tests/<n>/devenv.nix`, `tests/<n>/devenv.yaml` | yes |
| `docs/src/individual-docs/languages/<n>.md` or `docs/src/content/docs/integrations/<n>.md` | yes |
| `<n>/devenv.nix`, `<n>/devenv.yaml` (import dir) | no |
| `tests/<n>/eval.nix` (pure eval test) | no |
| `examples/<n>/` (consumer through the flake input) | no |

Local-only infrastructure that never goes upstream: `checks/`, `rules/`, `sgconfig.yml`,
`tools/`, and the 100-character line limit.

## Running the checks

```bash
nix fmt                                  # format
nix flake check -L                       # every check above except check-commits
nix build .#checks.x86_64-linux.layout   # one check
nix run .#check-commits -- origin/main..HEAD
cd tests/<n> && devenv test
```

[contributing]: https://github.com/cachix/devenv/blob/main/docs/src/content/docs/community/contributing.md
[create-language]: https://github.com/cachix/devenv/blob/main/.agents/skills/create-language/SKILL.md
[create-service]: https://github.com/cachix/devenv/blob/main/.agents/skills/create-service/SKILL.md
[devenv.nix]: https://github.com/cachix/devenv/blob/main/devenv.nix
