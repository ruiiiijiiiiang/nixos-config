{
  config,
  consts,
  lib,
  secretsDir,
  ...
}:
let
  inherit (consts)
    addresses
    domain
    endpoints
    subdomains
    ;
  cfg = config.custom.services.networking.cloudflared;

  homeIngressFqdns = map (subdomain: "${subdomain}.${domain}") [
    subdomains.vm-public.website
    subdomains.vm-public.microbin
    subdomains.vm-public.krawl
  ];
  edgeObserveIngressFqdns = [
    endpoints.gatus-server
    endpoints.ntfy-server
  ];

  mkIngress =
    {
      service,
      originServerName,
    }:
    {
      inherit service;
      originRequest = {
        inherit originServerName;
      };
    };

  tunnelDefinitions = {
    home = {
      credentialsSecretFile = secretsDir + "/networking/cloudflare/home-tunnel-credentials.age";
      ingress = lib.genAttrs homeIngressFqdns (
        fqdn:
        mkIngress {
          service = "https://${addresses.localhost}:443";
          originServerName = fqdn;
        }
      );
    };
    edge = {
      credentialsSecretFile = secretsDir + "/networking/cloudflare/edge-tunnel-credentials.age";
      ingress = lib.genAttrs edgeObserveIngressFqdns (
        fqdn:
        mkIngress {
          service = "https://${addresses.localhost}:443";
          originServerName = fqdn;
        }
      );
    };
  };
in
{
  options.custom.services.networking.cloudflared = {
    enable = lib.mkEnableOption "Enable Cloudflare Tunnel";

    tunnelName = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum (lib.attrNames tunnelDefinitions));
      default = null;
      description = "Name of the locally managed Cloudflare Tunnel to enable.";
    };
  };

  config = lib.mkMerge [
    {
      assertions = [
        {
          assertion = !cfg.enable || cfg.tunnelName != null;
          message = "Cloudflared requires a tunnel name when enabled.";
        }
      ];
    }
    (lib.mkIf (cfg.enable && cfg.tunnelName != null) (
      let
        tunnel = tunnelDefinitions.${cfg.tunnelName};
        credentialsSecretName = "cloudflared-${cfg.tunnelName}-credentials";
      in
      {
        age.secrets.${credentialsSecretName}.file = tunnel.credentialsSecretFile;

        services.cloudflared = {
          enable = true;
          tunnels.${cfg.tunnelName} = {
            default = "http_status:404";
            credentialsFile = config.age.secrets.${credentialsSecretName}.path;
            edgeIPVersion = "6";
            inherit (tunnel) ingress;
          };
        };
      }
    ))
  ];
}
