---
title: Cloudflare
---

Cloudflare tooling for the dev shell: wrangler plus opt-in extras. Everything defaults
off. Secrets such as `CLOUDFLARE_API_TOKEN` are out of scope; only non-secret env is set.

Some packages (workerd, create-cloudflare, cf-vault, and others) come from
[nixpkgs-extra](https://github.com/Jylhis/nixpkgs-extra). Declare that input with its
`default` and `overrides` overlays (cf-vault needs `overrides`).

```nix
{
  cloudflare = {
    enable = true;
    accountId = "0123456789abcdef0123456789abcdef";
    workers.workerd.enable = true;
    tunnel.enable = true;
    api.enable = true;
  };
}
```

npm dev-dependencies (miniflare, `@cloudflare/vite-plugin`, a project-pinned wrangler)
belong in the project's `package.json`. The standalone workerd version must match the
dependency of the wrangler you use.

## Options

| Option | Default | Description |
| --- | --- | --- |
| `cloudflare.enable` | `false` | Enable the module. |
| `cloudflare.accountId` | `null` | Exported as `CLOUDFLARE_ACCOUNT_ID`. |
| `cloudflare.wrangler.package` | `pkgs.wrangler` | The wrangler CLI to put on PATH. |
| `cloudflare.telemetry.enable` | `false` | When off, sets `WRANGLER_SEND_METRICS=false`. |
| `cloudflare.workers.workerd.enable` | `false` | Standalone workerd runtime. |
| `cloudflare.workers.rust.enable` | `false` | worker-build for Rust Workers. |
| `cloudflare.scaffold.enable` | `false` | create-cloudflare (C3) scaffolder. |
| `cloudflare.tunnel.enable` | `false` | The cloudflared CLI. |
| `cloudflare.api.enable` | `false` | flarectl. |
| `cloudflare.api.cf-vault.enable` | `false` | cf-vault keychain-backed token helper. |
| `cloudflare.infra.enable` | `false` | cf-terraforming. |
| `cloudflare.pki.enable` | `false` | cfssl. |
