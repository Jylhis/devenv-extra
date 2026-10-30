{
  pkgs,
  lib,
  stub,
}:
let
  evalWith =
    settings:
    (lib.evalModules {
      modules = [
        stub
        ../../src/modules/integrations/cloudflare.nix
        { _module.args = { inherit pkgs; }; }
        { cloudflare = settings; }
      ];
    }).config;

  off = evalWith { };
  base = evalWith { enable = true; };
  full = evalWith {
    enable = true;
    accountId = "acct";
    workers.workerd.enable = true;
    workers.rust.enable = true;
    scaffold.enable = true;
    tunnel.enable = true;
    tunnel.quick.enable = true;
    api.enable = true;
    api.cf-vault.enable = true;
    infra.enable = true;
    pki.enable = true;
    mcp.enable = true;
  };
in
assert off.packages == [ ] && off.env == { } && off.processes == { };
assert lib.length base.packages == 1;
assert base.env == { WRANGLER_SEND_METRICS = "false"; };
assert full.processes ? cloudflare-tunnel;
assert lib.hasInfix "--url http://127.0.0.1:8787" full.processes.cloudflare-tunnel.exec;
assert lib.length full.packages == 9;
assert full.env.CLOUDFLARE_ACCOUNT_ID == "acct";
assert !off.claude.code.enable;
assert full.claude.code.enable;
assert full.claude.code.settingsPath == ".devenv/state/claude-settings.json";
assert full.claude.code.mcpServers ? cloudflare-dns-analytics;
assert lib.length (lib.attrNames full.claude.code.mcpServers) == 6;
assert lib.all (s: s.type == "http" && lib.hasSuffix "/mcp" s.url) (
  lib.attrValues full.claude.code.mcpServers
);
true
