{
  config,
  consts,
  inputs,
  lib,
  pkgs,
  helpers,
  ...
}:
let
  inherit (consts)
    addresses
    domains
    subdomains
    ports
    ;
  inherit (helpers) mkVirtualHost getHostAddress;
  inherit (inputs.self) nixosConfigurations;
  cfg = config.custom.services.observability.prometheus.server;
  prometheus-fqdn = "${subdomains.${config.networking.hostName}.prometheus}.${domains.home}";
  grafana-fqdn = "${subdomains.${config.networking.hostName}.grafana}.${domains.home}";
  monitoredExporters = {
    inherit (ports.prometheus.exporters)
      # crowdsec
      kea
      nginx
      node
      podman
      wireguard
      ;
  };

  mkScrapeJob = exporterName: port: {
    job_name = "${exporterName}-exporter";
    scrape_interval = "30s";
    static_configs = [
      {
        targets = lib.pipe nixosConfigurations [
          (lib.filterAttrs (
            _: hostConfig:
            hostConfig.config.custom.services.observability.prometheus.exporters.${exporterName}.enable or false
          ))
          (lib.mapAttrsToList (
            hostname: _: "${getHostAddress { inherit config hostname; }}:${toString port}"
          ))
        ];
      }
    ];
  };

  # Generate the hash by running: nix-prefetch-url <url>
  crowdsec-dashboard = pkgs.fetchurl {
    name = "crowdsec-dashboard.json";
    url = "https://grafana.com/api/dashboards/21419/revisions/6/download";
    sha256 = "1dggzvx2ircakkv1whb2yzvnxsfy7a2iy5jxq42a2q9hlnzx5xp1";
  };

  kea-exporter-dashboard = pkgs.fetchurl {
    name = "kea-exporter.json";
    url = "https://grafana.com/api/dashboards/12688/revisions/4/download";
    sha256 = "1rq8yax192s5knf6lw3sl9rq55xirm1di8ngnqc07b7mmf5gjj7x";
  };

  nginx-exporter-dashboard = pkgs.fetchurl {
    name = "nginx-exporter.json";
    url = "https://grafana.com/api/dashboards/12767/revisions/2/download";
    sha256 = "1zkx8nhh05rzsc4di81wc90gvfc7k2nby149cx6y6y8iaibgz3sn";
  };

  node-exporter-dashboard = pkgs.fetchurl {
    name = "node-exporter.json";
    url = "https://grafana.com/api/dashboards/1860/revisions/42/download";
    sha256 = "0phjy96kq4kymzggm0r51y8i2s2z2x3p69bd5nx4n10r33mjgn54";
  };

  podman-exporter-dashboard = pkgs.fetchurl {
    name = "podman-exporter.json";
    url = "https://grafana.com/api/dashboards/21559/revisions/1/download";
    sha256 = "1aqirx7cjnvn0fmy872nbkxh5xgk3rgz0dllg12j1nismc4mcklb";
  };

  wireguard-exporter-dashboard = pkgs.fetchurl {
    name = "wireguard-exporter.json";
    url = "https://grafana.com/api/dashboards/17251/revisions/1/download";
    sha256 = "13qganba7c3b9vahxfc059iingzq5dw46vhl3bzvr7jfp3m8dh7s";
  };

  grafana-dashboards = pkgs.runCommand "grafana-dashboards" { } ''
    mkdir -p $out

    # Sanitize the json data sources
    install_dash() {
      sed -e 's/''${DS_PROMETHEUS-DNTG}/prometheus/g' \
          -e 's/''${DS_PROMETHEUS}/prometheus/g' \
          -e 's/''${ds_prometheus}/prometheus/g' \
      "$1" > "$out/$2"
    }

    # install_dash ${crowdsec-dashboard} "crowdsec-dashboard.json"
    install_dash ${kea-exporter-dashboard} "kea-exporter.json"
    install_dash ${nginx-exporter-dashboard} "nginx-exporter.json"
    install_dash ${node-exporter-dashboard} "node-exporter.json"
    install_dash ${podman-exporter-dashboard} "podman-exporter.json"
    install_dash ${wireguard-exporter-dashboard} "wireguard-exporter.json"
  '';

in
{
  options.custom.services.observability.prometheus.server = with lib; {
    enable = mkEnableOption "Prometheus metrics server";
  };

  config = lib.mkIf cfg.enable {
    age.secrets = {
      grafana-secret-key = {
        file = ../../../../secrets/grafana-secret-key.age;
        mode = "440";
        owner = "grafana";
        group = "grafana";
      };
    };

    services = {
      prometheus = {
        enable = true;
        port = ports.prometheus.server;
        scrapeConfigs = lib.mapAttrsToList mkScrapeJob monitoredExporters;
      };

      grafana = {
        enable = true;
        settings = {
          server = {
            root_url = "https://${grafana-fqdn}";
            http_addr = addresses.any;
            http_port = ports.grafana;
            domain = addresses.localhost;
          };
          security.secret_key = "$__file{${config.age.secrets.grafana-secret-key.path}}";
          auth = {
            oauth_allow_insecure_email_lookup = true;
          };
        };

        provision = {
          enable = true;
          datasources.settings = {
            apiVersion = 1;
            datasources = [
              {
                name = "Prometheus";
                type = "prometheus";
                uid = "prometheus";
                access = "proxy";
                url = "http://${addresses.localhost}:${toString ports.prometheus.server}";
              }
            ];
          };
          dashboards.settings.providers = [
            {
              name = "Homelab Dashboards";
              options.path = grafana-dashboards;
            }
          ];
        };
      };

      nginx.virtualHosts = {
        "${prometheus-fqdn}" = mkVirtualHost {
          fqdn = prometheus-fqdn;
          port = ports.prometheus.server;
        };

        "${grafana-fqdn}" = mkVirtualHost {
          fqdn = grafana-fqdn;
          port = ports.grafana;
        };
      };
    };
  };
}
