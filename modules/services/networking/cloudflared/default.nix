{
  config,
  consts,
  helpers,
  lib,
  secretsDir,
  ...
}:
let
  inherit (consts)
    addresses
    domain
    edge-observability
    ports
    subdomains
    ;
  inherit (helpers) getHostAddress;
  cfg = config.custom.services.networking.cloudflared;

  homeSubdomains = [
    subdomains.vm-public.website
    subdomains.vm-public.microbin
    subdomains.vm-public.krawl
  ];
  edgeObserveSubdomains = [
    {
      fqdn = edge-observability.gatus-server;
      port = ports.gatus;
    }
    {
      fqdn = edge-observability.ntfy-server;
      port = ports.ntfy;
    }
  ];

  mkIngress =
    {
      service,
      originRequest ? null,
    }:
    { inherit service; } // lib.optionalAttrs (originRequest != null) { inherit originRequest; };

  mkHomeIngress =
    fqdn:
    mkIngress {
      service = "https://${getHostAddress "vm-public"}:443";
      originRequest = {
        originServerName = fqdn;
        noTLSVerify = true;
      };
    };

  defaultHomeIngress = lib.genAttrs (map (
    subdomain: "${subdomain}.${domain}"
  ) homeSubdomains) mkHomeIngress;

  mkEdgeObserveIngress =
    { fqdn, port }:
    lib.nameValuePair fqdn (mkIngress {
      service = "https://${addresses.localhost}:443";
      originRequest.originServerName = fqdn;
    });

  defaultEdgeObserveIngress = lib.listToAttrs (map mkEdgeObserveIngress edgeObserveSubdomains);

  tunnelDefinitions = {
    home = {
      credentialsSecretFile = secretsDir + "/networking/cloudflare/home-tunnel-credentials.age";
      ingress = defaultHomeIngress;
    };
    edge-observe = {
      credentialsSecretFile = secretsDir + "/networking/cloudflare/edge-observe-tunnel-credentials.age";
      ingress = defaultEdgeObserveIngress;
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
            inherit (tunnel) ingress;
          };
        };
      }
    ))
  ];
}
