# devenv-extra

Reusable [devenv](https://devenv.sh) modules for tooling that nixpkgs and devenv do not
cover. Every module is off by default until a project enables it. The layout mirrors
[cachix/devenv](https://github.com/cachix/devenv), so a module can be upstreamed as is.

Packages that nixpkgs lacks come from
[nixpkgs-extra](https://github.com/Jylhis/nixpkgs-extra).

## Usage

Declare the inputs and import a module in `devenv.yaml`. Declare nixpkgs-extra with both
overlays yourself: `default` adds packages, `overrides` replaces nixpkgs attributes.
devenv does not read the `devenv.yaml` of a directory imported through an input.

```yaml
inputs:
  nixpkgs:
    url: github:NixOS/nixpkgs/nixos-unstable
  devenv-extra:
    url: github:Jylhis/devenv-extra
    flake: false
  nixpkgs-extra:
    url: github:Jylhis/nixpkgs-extra
    overlays:
      - default
      - overrides
imports:
  - devenv-extra/<module>
```

Then enable the module in `devenv.nix`. Options are documented under `docs/src/`, and
`examples/` holds one consumer per module.

If you vendor this repository inside your project, import by local path instead
(`imports: [ ./vendor/devenv-extra/<module> ]`). devenv then merges the module's own
`devenv.yaml`, which already declares nixpkgs-extra.

## Development

```bash
nix fmt                          # treefmt: nixpkgs-fmt for src/modules, nixfmt elsewhere
nix flake check                  # eval tests, options doc, format, ast-grep
nix build .#options-doc          # CommonMark reference of all options
nix flake check --override-input nixpkgs-extra path:../nixpkgs-extra
cd tests/<name> && devenv test   # smoke test in a real devenv shell
```

See `AGENTS.md` for the layout and conventions.

## License

MIT, see `LICENSE`.
