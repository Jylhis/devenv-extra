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
    api.enable = true;
    api.cf-vault.enable = true;
    infra.enable = true;
    pki.enable = true;
  };
in
assert off.packages == [ ] && off.env == { } && off.processes == { };
assert lib.length base.packages == 1;
assert base.env == { WRANGLER_SEND_METRICS = "false"; };
assert lib.length full.packages == 9;
assert full.env.CLOUDFLARE_ACCOUNT_ID == "acct";
true
