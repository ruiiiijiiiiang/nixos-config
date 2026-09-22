{
  config,
  consts,
  secretsDir,
  ...
}:
let
  inherit (consts) addresses;
  hostName = "cloud-observe";
  wgInterface = "wg0";
in
{
  system.stateVersion = "25.11";
  networking.hostName = hostName;

  age.secrets = {
    wireguard-cloud-observe-private-key.file =
      secretsDir + "/networking/wireguard/cloud-observe-private-key.age";
    wireguard-cloud-observe-preshared-key.file =
      secretsDir + "/networking/wireguard/cloud-observe-preshared-key.age";
  };

  custom = {
    roles = {
      headless = {
        networking.enable = true;
        packages.enable = true;
        security.enable = true;
        services.enable = true;
      };
    };

    services = {
      networking = {
        cloudflared = {
          enable = true;
          tunnelName = "edge-observe";
        };
        nginx.enable = true;

        wireguard.client = {
          enable = true;
          inherit hostName wgInterface;
          activationMode = "persistent";
          enableDns = false;
          privateKeyFile = config.age.secrets.wireguard-cloud-observe-private-key.path;
          presharedKeyFile = config.age.secrets.wireguard-cloud-observe-preshared-key.path;
        };
      };

      observability = {
        beszel.agent = {
          enable = true;
          interface = wgInterface;
        };
        gatus.enable = true;
        ntfy.enable = true;
        prometheus = {
          exporters = {
            interface = wgInterface;
            nginx.enable = true;
            node.enable = true;
            scrapeAddress = addresses.wg.hosts.${hostName};
          };
        };
      };

      security = {
        fail2ban.enable = true;
      };
    };
  };

}
