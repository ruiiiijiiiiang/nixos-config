{
  config,
  lib,
  consts,
  utilFns,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (consts)
    addresses
    domains
    subdomains
    ports
    ;
  inherit (utilFns) mkVirtualHost;
  cfg = config.selfhost.homepage;
  fqdn = "${subdomains.${config.networking.hostName}.homepage}.${domains.home}";
in
{
  config = mkIf cfg.enable {
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
                "Stirling PDF" = {
                  icon = "stirling-pdf";
                  href = "https://${subdomains.vm-app.stirlingpdf}.${domains.home}";
                  description = "PDF Editor";
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
                "Microbin" = {
                  icon = "microbin";
                  href = "https://${subdomains.vm-app.microbin}.${domains.home}";
                  description = "Pastebin";
                };
              }
              {
                "Nextcloud" = {
                  icon = "nextcloud";
                  href = "https://${subdomains.vm-app.nextcloud}.${domains.home}";
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
                "Yourls" = {
                  icon = "yourls";
                  href = "https://${subdomains.vm-app.yourls}.${domains.home}/admin";
                  description = "URL Shortener";
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
                "Portainer" = {
                  icon = "portainer";
                  href = "https://${subdomains.vm-app.portainer}.${domains.home}";
                  description = "Container Dashboard";
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
