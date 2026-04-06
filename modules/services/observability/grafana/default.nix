{
  config,
  consts,
  lib,
  pkgs,
  helpers,
  ...
}:
let
  inherit (consts)
    addresses
    domain
    subdomains
    ports
    ;
  inherit (helpers) mkVirtualHost;
  cfg = config.custom.services.observability.grafana;
  fqdn = "${subdomains.${config.networking.hostName}.grafana}.${domain}";
  systemd-logs-json = import ./systemd-logs.json.nix;

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

  libvirt-exporter-dashboard = pkgs.fetchurl {
    name = "libvirt-exporter.json";
    url = "https://grafana.com/api/dashboards/19639/revisions/5/download";
    sha256 = "0lflkv9df30jrqyrp7jfkhxnf5jdfziin2vlv3a2k1lxx9m8qq16";
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

  restic-exporter-dashboard = pkgs.fetchurl {
    name = "restic-exporter.json";
    url = "https://grafana.com/api/dashboards/17554/revisions/3/download";
    sha256 = "0p06z60gxcnv1xswq228583apr8p2m8k8czbqw0hx5031rmgdjwc";
  };

  wireguard-exporter-dashboard = pkgs.fetchurl {
    name = "wireguard-exporter.json";
    url = "https://grafana.com/api/dashboards/17251/revisions/1/download";
    sha256 = "13qganba7c3b9vahxfc059iingzq5dw46vhl3bzvr7jfp3m8dh7s";
  };

  systemd-logs-dashboard = pkgs.writeText "systemd-logs.json" systemd-logs-json;

  grafana-dashboards = pkgs.runCommand "grafana-dashboards" { } /* bash */ ''
    mkdir -p $out

    # Sanitize the json data sources since different dashboards use different names.
    # When adding a new dashboard, make sure to curl the json and check for datasource.uid.
    # Add the data source name for sanitization if not present.
    install_dash() {
      sed -e 's/''${DS_PROMETHEUS-DNTG}/prometheus/g' \
          -e 's/''${DS_PROMETHEUS}/prometheus/g' \
          -e 's/''${ds_prometheus}/prometheus/g' \
      "$1" > "$out/$2"
    }

    # install_dash ${crowdsec-dashboard} "crowdsec-dashboard.json"
    install_dash ${kea-exporter-dashboard} "kea-exporter.json"
    install_dash ${libvirt-exporter-dashboard} "libvirt-exporter.json"
    install_dash ${nginx-exporter-dashboard} "nginx-exporter.json"
    install_dash ${node-exporter-dashboard} "node-exporter.json"
    install_dash ${podman-exporter-dashboard} "podman-exporter.json"
    install_dash ${restic-exporter-dashboard} "restic-exporter.json"
    install_dash ${wireguard-exporter-dashboard} "wireguard-exporter.json"
    cp ${systemd-logs-dashboard} $out/systemd-logs.json
  '';

in
{
  options.custom.services.observability.grafana = with lib; {
    enable = mkEnableOption "Enable Grafana";
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.custom.services.observability.prometheus.server.enable;
        message = "Grafana requires observability.prometheus.server for the provisioned Prometheus datasource.";
      }
      {
        assertion = config.custom.services.observability.loki.server.enable;
        message = "Grafana requires observability.loki.server for the provisioned Loki datasource.";
      }
    ];

    age.secrets = {
      grafana-secret-key = {
        file = ../../../../secrets/grafana-secret-key.age;
        mode = "440";
        owner = "grafana";
        group = "grafana";
      };
    };

    services = {
      grafana = {
        enable = true;
        settings = {
          server = {
            root_url = "https://${fqdn}";
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
              {
                name = "Loki";
                type = "loki";
                uid = "loki";
                access = "proxy";
                url = "http://${addresses.localhost}:${toString ports.loki.server}";
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

      nginx.virtualHosts."${fqdn}" = mkVirtualHost {
        inherit fqdn;
        port = ports.grafana;
      };
    };
  };
}
