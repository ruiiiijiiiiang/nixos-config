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
    domains
    subdomains
    ports
    ;
  inherit (helpers) mkVirtualHost;
  cfg = config.custom.services.observability.grafana;
  fqdn = "${subdomains.${config.networking.hostName}.grafana}.${domains.home}";

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

  systemd-logs-dashboard = pkgs.writeText "systemd-logs.json" /* json */ ''
    {
      "uid": "systemd-logs-viewer",
      "title": "Systemd Logs Viewer",
      "tags": ["loki", "systemd"],
      "timezone": "browser",
      "refresh": "10s",
      "templating": {
        "list": [
          {
            "name": "host",
            "type": "query",
            "datasource": "Loki",
            "query": "label_values({job=\"systemd-journal\"}, host)",
            "refresh": 1,
            "includeAll": true,
            "multi": true
          },
          {
            "name": "unit",
            "type": "query",
            "datasource": "Loki",
            "query": "label_values({job=\"systemd-journal\", host=~\"$host\"}, unit)",
            "refresh": 1,
            "includeAll": true,
            "multi": true
          }
        ]
      },
      "panels": [
        {
          "type": "logs",
          "title": "Journal Output: $unit on $host",
          "datasource": "Loki",
          "gridPos": { "h": 20, "w": 24, "x": 0, "y": 0 },
          "targets": [
            {
              "expr": "{job=\"systemd-journal\", host=~\"$host\", unit=~\"$unit\"}"
            }
          ]
        }
      ]
    }
  '';

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
    cp ${systemd-logs-dashboard} $out/systemd-logs.json
  '';

in
{
  options.custom.services.observability.grafana = with lib; {
    enable = mkEnableOption "Grafana visualization platform";
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
