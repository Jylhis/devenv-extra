## Summary

<!-- What does this change and why? -->

## Checks

See [CONTRIBUTING.md](../CONTRIBUTING.md) for what each check enforces.

- [ ] `nix fmt` leaves no diff
- [ ] `nix flake check` passes (`layout`, `option-style`, `defaults-off`, `vanilla-<name>`,
      `markdownlint`, `editorconfig`, `ast-grep`)
- [ ] `devenv test` passes in `tests/<name>`
- [ ] docs updated
- [ ] `nix run .#check-commits -- origin/main..HEAD` passes (one module per commit)
