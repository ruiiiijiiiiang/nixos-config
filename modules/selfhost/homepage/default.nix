{
  config,
  consts,
  lib,
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
  cfg = config.custom.selfhost.homepage;
  fqdn = "${subdomains.${config.networking.hostName}.homepage}.${domains.home}";
in
{
  options.custom.selfhost.homepage = with lib; {
    enable = mkEnableOption "Homepage dashboard";
  };

  config = lib.mkIf cfg.enable {
    services = {
      homepage-dashboard = {
        enable = true;
        listenPort = ports.homepage;
        allowedHosts = "home.${domains.home}, ${addresses.localhost}, localhost";

        settings = {
          title = "Homepage";
          background = {
            image = "https://i.imgur.com/oYFsq5y.jpeg";
          };
          cardBlur = "xl";
          layout = {
            "Apps" = {
              style = "row";
              columns = 4;
            };
            "System" = {
              style = "row";
              columns = 4;
            };
          };
        };

        widgets = [
          {
            greeting = {
              text_size = "xl";
              text = "Sup homie";
            };
          }
          {
            resources = {
              cpu = true;
              memory = true;
              disk = "/data";
              uptime = true;
            };
          }
        ];

        services = [
          {
            "Apps" = [
              {
                "Pocket ID" = {
                  icon = "pocket-id";
                  href = "https://${subdomains.vm-app.pocketid}.${domains.home}";
                  description = "Identity Provider";
                };
              }
              {
                "Home Assistant" = {
                  icon = "home-assistant";
                  href = "https://${subdomains.pi.homeassistant}.${domains.home}";
                  description = "Home Automation System";
                };
              }
              {
                "Opencloud" = {
                  icon = "open-cloud";
                  href = "https://${subdomains.vm-app.opencloud}.${domains.home}";
                  description = "Cloud Storage";
                };
              }
              {
                "Immich" = {
                  icon = "immich";
                  href = "https://${subdomains.vm-app.immich}.${domains.home}";
                  description = "Photos & Video";
                };
              }
              {
                "Paperless" = {
                  icon = "paperless";
                  href = "https://${subdomains.vm-app.paperless}.${domains.home}";
                  description = "Document Archive";
                };
              }
              {
                "Vaultwarden" = {
                  icon = "vaultwarden";
                  href = "https://${subdomains.vm-app.vaultwarden}.${domains.home}";
                  description = "Password Manager";
                };
              }
              {
                "Karakeep" = {
                  icon = "karakeep";
                  href = "https://${subdomains.vm-app.karakeep}.${domains.home}";
                  description = "Bookmark";
                };
              }
              {
                "Memos" = {
                  icon = "memos";
                  href = "https://${subdomains.vm-app.memos}.${domains.home}";
                  description = "Note Taking";
                };
              }
              {
                "Microbin" = {
                  icon = "microbin";
                  href = "https://${subdomains.vm-app.microbin}.${domains.home}";
                  description = "Pastebin";
                };
              }
              {
                "Dawarich" = {
                  icon = "dawarich";
                  href = "https://${subdomains.vm-app.dawarich}.${domains.home}";
                  description = "Location Tracking";
                };
              }
              {
                "Reitti" = {
                  icon = "https://cdn.jsdelivr.net/gh/selfhst/icons@main/png/reitti.png";
                  href = "https://${subdomains.vm-app.reitti}.${domains.home}";
                  description = "Location Tracking";
                };
              }
              {
                "Yourls" = {
                  icon = "yourls";
                  href = "https://${subdomains.vm-app.yourls}.${domains.home}/admin";
                  description = "URL Shortener";
                };
              }
              {
                "Stirling PDF" = {
                  icon = "stirling-pdf";
                  href = "https://${subdomains.vm-app.stirlingpdf}.${domains.home}";
                  description = "PDF Editor";
                };
              }
              {
                "Calendar Parser" = {
                  icon = "p-cal";
                  href = "https://calendar-parse.ruiiiijiiiiang.deno.net";
                  description = "Parse CSV Calendar from Pam's Boss";
                };
              }
              {
                "Blog" = {
                  icon = "booklogr";
                  href = "https://public.ruijiang.me/blog/0";
                  description = "Rui's Blog";
                };
              }
            ];
          }
          {
            "System" = [
              {
                "Proxmox" = {
                  icon = "proxmox";
                  href = "https://${addresses.home.hosts.proxmox}:${toString ports.proxmox}";
                  description = "Virtual Environment Hypervisor";
                };
              }
              {
                "Gatus" = {
                  icon = "gatus";
                  href = "https://${subdomains.vm-monitor.gatus}.${domains.home}";
                  description = "Server Health Monitoring";
                };
              }
              {
                "Dockhand" = {
                  icon = "https://cdn.jsdelivr.net/gh/selfhst/icons@main/png/dockhand.png";
                  href = "https://${subdomains.vm-monitor.dockhand}.${domains.home}";
                  description = "Container Management Dashboard";
                };
              }
              {
                "Beszel" = {
                  icon = "beszel";
                  href = "https://${subdomains.vm-monitor.beszel}.${domains.home}";
                  description = "Server Monitoring";
                };
              }
              {
                "Prometheus" = {
                  icon = "prometheus";
                  href = "https://${subdomains.vm-monitor.prometheus}.${domains.home}";
                  description = "Metrics Monitoring";
                };
              }
              {
                "Grafana" = {
                  icon = "grafana";
                  href = "https://${subdomains.vm-monitor.grafana}.${domains.home}";
                  description = "Metrics Visualization";
                };
              }
              {
                "Wazuh" = {
                  icon = "wazuh";
                  href = "https://${subdomains.vm-monitor.wazuh}.${domains.home}";
                  description = "Security Monitoring";
                };
              }
              {
                "Evebox" = {
                  icon = "evebox";
                  href = "https://${subdomains.vm-network.evebox}.${domains.home}";
                  description = "IDS Event Viewer";
                };
              }
              {
                "Scanopy" = {
                  icon = "scanopy";
                  href = "https://${subdomains.vm-monitor.scanopy}.${domains.home}";
                  description = "Network Scanner";
                };
              }
              {
                "Syncthing" = {
                  icon = "syncthing";
                  href = "https://${subdomains.vm-app.syncthing}.${domains.home}";
                  description = "File Sync Tool";
                };
              }
              {
                "Zwave" = {
                  icon = "z-wave-js-ui";
                  href = "https://${subdomains.pi.zwave}.${domains.home}";
                  description = "Zwave Device Manager";
                };
              }
              {
                "Pihole" = {
                  icon = "pi-hole";
                  href = "https://${subdomains.vm-network.pihole}.${domains.home}";
                  description = "DNS Ad Blocker";
                };
              }
              {
                "Pihole Backup 1" = {
                  icon = "pi-hole";
                  href = "https://${subdomains.pi.pihole}.${domains.home}";
                  description = "DNS Ad Blocker";
                };
              }
              {
                "Pihole Backup 2" = {
                  icon = "pi-hole";
                  href = "https://${addresses.home.hosts.pi-legacy}/admin";
                  description = "DNS Ad Blocker";
                };
              }
            ];
          }
        ];
      };

      nginx.virtualHosts."${fqdn}" = mkVirtualHost {
        inherit fqdn;
        port = ports.homepage;
      };
    };
  };
}
