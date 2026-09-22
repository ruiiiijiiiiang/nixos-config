{
  config,
  consts,
  helpers,
  inputs,
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
    ;
  inherit (helpers) getEnabledServices getHostAddress mkVirtualHost;
  inherit (inputs.self) nixosConfigurations;
  cfg = config.custom.services.observability.gatus;
  standardAlert = {
    type = "ntfy";
    failure-threshold = 3;
    success-threshold = 2;
    send-on-resolved = true;
  };
  servicePolicies = {
    default = {
      route = "private";
      path = "/";
      conditions = [
        "[STATUS] >= 200"
        "[STATUS] < 400"
      ];
    };
    gatus.route = "public";
    krawl = {
      route = "public";
      path = "/krawl-honeypot-dashboard";
      conditions = [ "[STATUS] == 200" ];
    };
    microbin.route = "public";
    ntfy = {
      route = "public";
      path = "/v1/health";
      conditions = [ "[STATUS] == 200" ];
    };
    website.route = "public";
  };
  getServicePolicy = serviceName: servicePolicies.default // (servicePolicies.${serviceName} or { });
  serviceMonitors = lib.concatMap (
    hostName:
    lib.mapAttrsToList
      (
        serviceName: subdomain:
        let
          policy = getServicePolicy serviceName;
        in
        {
          inherit hostName policy serviceName;
          fqdn = "${subdomain}.${domain}";
        }
      )
      (getEnabledServices {
        config = nixosConfigurations.${hostName}.config;
      })
  ) (builtins.attrNames nixosConfigurations);
  privateServiceHosts = lib.unique (
    map (monitor: "${getHostAddress monitor.hostName} ${monitor.fqdn}") (
      lib.filter (monitor: monitor.policy.route == "private") serviceMonitors
    )
  );
  serviceEndpoints = map (monitor: {
    name = "${monitor.hostName}: ${monitor.serviceName}";
    group =
      if monitor.policy.route == "public" then "public-services" else "${monitor.hostName}-services";
    url = "https://${monitor.fqdn}${monitor.policy.path}";
    interval = "10m";
    inherit (monitor.policy) conditions;
    alerts = [ standardAlert ];
  }) serviceMonitors;
  infrastructureEndpoints = [
    {
      name = "ntfy public route";
      group = "edge-dependencies";
      url = "https://${edge-observability.ntfy-server}/v1/health";
      interval = "5m";
      conditions = [ "[STATUS] == 200" ];
      alerts = [ standardAlert ];
    }
    {
      name = "Home WireGuard gateway";
      group = "home-connectivity";
      url = "icmp://${addresses.wg.hosts.vm-network}";
      interval = "1m";
      conditions = [ "[CONNECTED] == true" ];
      alerts = [ standardAlert ];
    }
  ];
in
{
  options.custom.services.observability.gatus = {
    enable = lib.mkEnableOption "Enable Gatus";

    fqdn = lib.mkOption {
      type = lib.types.str;
      default = edge-observability.gatus-server;
      description = "Externally advertised Gatus FQDN.";
    };
  };

  config = lib.mkIf cfg.enable {
    age.secrets.gatus-ntfy-publisher-environment.file =
      secretsDir + "/observability/ntfy/gatus-publisher.env.age";

    networking.extraHosts = lib.mkAfter (lib.concatStringsSep "\n" privateServiceHosts);

    custom.services.networking.nginx.additionalFqdns = [ cfg.fqdn ];

    services.gatus = {
      enable = true;
      environmentFile = config.age.secrets.gatus-ntfy-publisher-environment.path;
      settings = {
        endpoints = serviceEndpoints ++ infrastructureEndpoints;
        web = {
          address = addresses.localhost;
          port = ports.gatus;
        };
        alerting.ntfy = {
          url = "http://${addresses.localhost}:${toString ports.ntfy}";
          topic = edge-observability.ntfy-topics.gatus-alerts;
          token = "\${NTFY_TOKEN}";
          priority = 4;
          click = "https://${cfg.fqdn}";
        };
      };
    };

    services.nginx.virtualHosts."${cfg.fqdn}" = mkVirtualHost {
      fqdn = cfg.fqdn;
      port = ports.gatus;
    };
  };
}
