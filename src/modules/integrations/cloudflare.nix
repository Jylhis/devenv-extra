# Cloudflare tooling: wrangler plus opt-in extras. Everything defaults off.
# Secrets (CLOUDFLARE_API_TOKEN) are out of scope: this module exports non-secret env only.
{ lib, pkgs, config, ... }:
let
  cfg = config.cloudflare;
in
{
  options.cloudflare = {
    enable = lib.mkEnableOption "Cloudflare tooling (wrangler and opt-in extras)";

    accountId = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Non-secret Cloudflare account id, exported as CLOUDFLARE_ACCOUNT_ID.";
    };

    wrangler.package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.wrangler;
      defaultText = lib.literalExpression "pkgs.wrangler";
      description = "The wrangler CLI to put on PATH.";
    };

    telemetry.enable = lib.mkEnableOption "wrangler telemetry (otherwise disabled)";

    # workerd's version must match the workerd dependency of the wrangler in use.
    workers.workerd.enable = lib.mkEnableOption "the standalone workerd runtime";

    workers.rust.enable = lib.mkEnableOption "worker-build for Rust Workers";

    scaffold.enable = lib.mkEnableOption "create-cloudflare (C3) project scaffolder";

    tunnel.enable = lib.mkEnableOption "the cloudflared tunnel CLI";

    tunnel.quick = {
      enable = lib.mkEnableOption "a devenv process running a credential-free quick tunnel";
      port = lib.mkOption {
        type = lib.types.port;
        default = 8787;
        description = "Local port the quick tunnel exposes on an ephemeral trycloudflare.com URL.";
      };
    };

    api.enable = lib.mkEnableOption "flarectl (Cloudflare API CLI)";

    api.cf-vault.enable = lib.mkEnableOption "cf-vault (keychain-backed Cloudflare token helper)";

    infra.enable = lib.mkEnableOption "cf-terraforming (import live Cloudflare state into HCL)";

    pki.enable = lib.mkEnableOption "cfssl (Cloudflare's PKI toolkit)";

  };

  config = lib.mkIf cfg.enable {
    packages = [ cfg.wrangler.package ]
      ++ lib.optional cfg.workers.workerd.enable pkgs.workerd
      ++ lib.optional cfg.workers.rust.enable pkgs.worker-build
      ++ lib.optional cfg.scaffold.enable pkgs.create-cloudflare
      ++ lib.optional cfg.tunnel.enable pkgs.cloudflared
      ++ lib.optional cfg.api.enable pkgs.flarectl
      ++ lib.optional cfg.api.cf-vault.enable pkgs.cf-vault
      ++ lib.optional cfg.infra.enable pkgs.cf-terraforming
      ++ lib.optional cfg.pki.enable pkgs.cfssl;

    # devenv has no cloudflared service module, so a plain process.
    processes = lib.mkIf (cfg.tunnel.enable && cfg.tunnel.quick.enable) {
      cloudflare-tunnel.exec = ''
        exec ${pkgs.cloudflared}/bin/cloudflared tunnel --no-autoupdate \
          --url http://127.0.0.1:${toString cfg.tunnel.quick.port}
      '';
    };

    env =
      lib.optionalAttrs (cfg.accountId != null) { CLOUDFLARE_ACCOUNT_ID = cfg.accountId; }
      // lib.optionalAttrs (!cfg.telemetry.enable) { WRANGLER_SEND_METRICS = "false"; };
  };
}
