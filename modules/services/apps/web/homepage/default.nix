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
  cfg = config.custom.services.apps.web.homepage;
  fqdn = "${subdomains.${config.networking.hostName}.homepage}.${domains.home}";
in
{
  options.custom.services.apps.web.homepage = with lib; {
    enable = mkEnableOption "Homepage dashboard";
  };

  config = lib.mkIf cfg.enable {
    services = {
      homepage-dashboard = {
        enable = true;
        listenPort = ports.homepage;
        allowedHosts = "${fqdn}, ${addresses.localhost}, localhost";

        settings = {
          title = "Homepage";
          background = {
            image = "https://i.imgur.com/heDeGHH.jpeg";
          };
          cardBlur = "xl";
          layout = {
            "Media" = {
              style = "row";
              columns = 6;
            };
            "Downloads" = {
              style = "row";
              columns = 6;
            };
            "Office" = {
              style = "row";
              columns = 6;
            };
            "Security" = {
              style = "row";
              columns = 6;
            };
            "Tools" = {
              style = "row";
              columns = 6;
            };
            "System" = {
              style = "row";
              columns = 6;
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
            "Media" = [
              {
                "Immich" = {
                  icon = "immich";
                  href = "https://${subdomains.vm-app.immich}.${domains.home}";
                  description = "Photos & Video";
                };
              }
              {
                "Jellyfin" = {
                  icon = "jellyfin";
                  href = "https://${subdomains.vm-app.jellyfin}.${domains.home}";
                  description = "Media Server";
                };
              }
            ];
          }
          {
            "Downloads" = [
              {
                "Sonarr" = {
                  icon = "sonarr";
                  href = "https://${subdomains.vm-app.sonarr}.${domains.home}";
                  description = "TV Series Management";
                };
              }
              {
                "Radarr" = {
                  icon = "radarr";
                  href = "https://${subdomains.vm-app.radarr}.${domains.home}";
                  description = "Movie Management";
                };
              }
              {
                "Lidarr" = {
                  icon = "lidarr";
                  href = "https://${subdomains.vm-app.lidarr}.${domains.home}";
                  description = "Music Management";
                };
              }
              {
                "Prowlarr" = {
                  icon = "prowlarr";
                  href = "https://${subdomains.vm-app.prowlarr}.${domains.home}";
                  description = "Indexer Management";
                };
              }
              {
                "Bazarr" = {
                  icon = "bazarr";
                  href = "https://${subdomains.vm-app.bazarr}.${domains.home}";
                  description = "Subtitle Management";
                };
              }
              {
                "qBittorrent" = {
                  icon = "qbittorrent";
                  href = "https://${subdomains.vm-app.qbittorrent}.${domains.home}";
                  description = "Torrent Client";
                };
              }
            ];
          }
          {
            "Office" = [
              {
                "Opencloud" = {
                  icon = "open-cloud";
                  href = "https://${subdomains.vm-app.opencloud}.${domains.home}";
                  description = "Cloud Storage";
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
                "Memos" = {
                  icon = "memos";
                  href = "https://${subdomains.vm-app.memos}.${domains.home}";
                  description = "Note Taking";
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
                  description = "Parse CSV Calendar";
                };
              }
            ];
          }
          {
            "Security" = [
              {
                "Pocket ID" = {
                  icon = "pocket-id";
                  href = "https://${subdomains.vm-app.pocketid}.${domains.home}";
                  description = "Identity Provider";
                };
              }
              {
                "Vaultwarden" = {
                  icon = "vaultwarden";
                  href = "https://${subdomains.vm-app.vaultwarden}.${domains.home}";
                  description = "Password Manager";
                };
              }
            ];
          }
          {
            "Tools" = [
              {
                "Home Assistant" = {
                  icon = "home-assistant";
                  href = "https://${subdomains.pi.homeassistant}.${domains.home}";
                  description = "Home Automation System";
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
                "Microbin" = {
                  icon = "microbin";
                  href = "https://${subdomains.vm-app.microbin}.${domains.home}";
                  description = "Pastebin";
                };
              }
              {
                "Syncthing" = {
                  icon = "syncthing";
                  href = "https://${subdomains.vm-app.syncthing}.${domains.home}";
                  description = "File Sync Tool";
                };
              }
            ];
          }
          {
            "System" = [
              {
                "Proxmox" = {
                  icon = "proxmox";
                  href = "https://${addresses.infra.hosts.proxmox}:${toString ports.proxmox}";
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
                "Myspeed" = {
                  icon = "myspeed";
                  href = "https://${subdomains.vm-monitor.myspeed}.${domains.home}";
                  description = "Speed Test Analysis";
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
                  href = "https://${addresses.infra.hosts.pi-legacy}/admin";
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
