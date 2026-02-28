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
    domain
    subdomains
    ports
    ;
  inherit (helpers) mkVirtualHost;
  cfg = config.custom.services.apps.web.homepage;
  fqdn = "${subdomains.${config.networking.hostName}.homepage}.${domain}";
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
          layout = [
            {
              "Media" = {
                style = "row";
                columns = 6;
                tab = "Apps";
              };
            }
            {
              "Office" = {
                style = "row";
                columns = 6;
                tab = "Apps";
              };
            }
            {
              "Tools" = {
                style = "row";
                columns = 6;
                tab = "Apps";
              };
            }
            {
              "Security" = {
                style = "row";
                columns = 6;
                tab = "Apps";
              };
            }
            {
              "Development" = {
                style = "row";
                columns = 6;
                tab = "System";
              };
            }
            {
              "Downloads" = {
                style = "row";
                columns = 6;
                tab = "System";
              };
            }
            {
              "Networking" = {
                style = "row";
                columns = 6;
                tab = "System";
              };
            }
            {
              "System" = {
                style = "row";
                columns = 6;
                tab = "System";
              };
            }
          ];
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
                  href = "https://${subdomains.vm-app.immich}.${domain}";
                  description = "Photos & Video";
                };
              }
              {
                "Jellyfin" = {
                  icon = "jellyfin";
                  href = "https://${subdomains.vm-app.jellyfin}.${domain}";
                  description = "Media Server";
                };
              }
            ];
          }
          {
            "Development" = [
              {
                "ByteStash" = {
                  icon = "bytestash";
                  href = "https://${subdomains.vm-app.bytestash}.${domain}";
                  description = "Code Snippets";
                };
              }
              {
                "Forgejo" = {
                  icon = "forgejo";
                  href = "https://${subdomains.vm-app.forgejo}.${domain}";
                  description = "Version Control";
                };
              }
            ];
          }
          {
            "Downloads" = [
              {
                "Sonarr" = {
                  icon = "sonarr";
                  href = "https://${subdomains.vm-app.sonarr}.${domain}";
                  description = "TV Series Management";
                };
              }
              {
                "Radarr" = {
                  icon = "radarr";
                  href = "https://${subdomains.vm-app.radarr}.${domain}";
                  description = "Movie Management";
                };
              }
              {
                "Lidarr" = {
                  icon = "lidarr";
                  href = "https://${subdomains.vm-app.lidarr}.${domain}";
                  description = "Music Management";
                };
              }
              {
                "Prowlarr" = {
                  icon = "prowlarr";
                  href = "https://${subdomains.vm-app.prowlarr}.${domain}";
                  description = "Indexer Management";
                };
              }
              {
                "Bazarr" = {
                  icon = "bazarr";
                  href = "https://${subdomains.vm-app.bazarr}.${domain}";
                  description = "Subtitle Management";
                };
              }
              {
                "qBittorrent" = {
                  icon = "qbittorrent";
                  href = "https://${subdomains.vm-app.qbittorrent}.${domain}";
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
                  href = "https://${subdomains.vm-app.opencloud}.${domain}";
                  description = "Cloud Storage";
                };
              }
              {
                "Paperless" = {
                  icon = "paperless";
                  href = "https://${subdomains.vm-app.paperless}.${domain}";
                  description = "Document Archive";
                };
              }
              {
                "Memos" = {
                  icon = "memos";
                  href = "https://${subdomains.vm-app.memos}.${domain}";
                  description = "Note Taking";
                };
              }
              {
                "Bento PDF" = {
                  icon = "bentopdf";
                  href = "https://www.bentopdf.com/index.html";
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
            "Authentication" = [
              {
                "Pocket ID" = {
                  icon = "pocket-id";
                  href = "https://${subdomains.vm-app.pocketid}.${domain}";
                  description = "Identity Provider";
                };
              }
              {
                "Vaultwarden" = {
                  icon = "vaultwarden";
                  href = "https://${subdomains.vm-app.vaultwarden}.${domain}";
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
                  href = "https://${subdomains.pi.homeassistant}.${domain}";
                  description = "Home Automation System";
                };
              }
              {
                "Zwave" = {
                  icon = "z-wave-js-ui";
                  href = "https://${subdomains.pi.zwave}.${domain}";
                  description = "Zwave Device Manager";
                };
              }
              {
                "Microbin" = {
                  icon = "microbin";
                  href = "https://${subdomains.vm-app.microbin}.${domain}";
                  description = "Pastebin";
                };
              }
              {
                "Karakeep" = {
                  icon = "karakeep";
                  href = "https://${subdomains.vm-app.karakeep}.${domain}";
                  description = "Bookmark";
                };
              }
              {
                "Reitti" = {
                  icon = "https://cdn.jsdelivr.net/gh/selfhst/icons@main/png/reitti.png";
                  href = "https://${subdomains.vm-app.reitti}.${domain}";
                  description = "Location Tracking";
                };
              }
              {
                "SearXNG" = {
                  icon = "searxng";
                  href = "https://${subdomains.vm-app.searxng}.${domain}";
                  description = "Search engine";
                };
              }
              {
                "OmniTools" = {
                  icon = "omni-tools";
                  href = "https://omnitools.app";
                  description = "Miscellaneous Utilities";
                };
              }
              {
                "Vert" = {
                  icon = "https://avatars.githubusercontent.com/u/198117259?s=48&v=4";
                  href = "https://vert.sh";
                  description = "File Converter";
                };
              }
              {
                "Syncthing" = {
                  icon = "syncthing";
                  href = "https://${subdomains.vm-app.syncthing}.${domain}";
                  description = "File Sync Tool";
                };
              }
            ];
          }
          {
            "Networking" = [
              {
                "Myspeed" = {
                  icon = "myspeed";
                  href = "https://${subdomains.vm-monitor.myspeed}.${domain}";
                  description = "Speed Test Analysis";
                };
              }
              {
                "Pihole" = {
                  icon = "pi-hole";
                  href = "https://${subdomains.vm-network.pihole}.${domain}";
                  description = "DNS Ad Blocker";
                };
              }
              {
                "Pihole Backup 1" = {
                  icon = "pi-hole";
                  href = "https://${subdomains.pi.pihole}.${domain}";
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
                  href = "https://${subdomains.vm-monitor.gatus}.${domain}";
                  description = "Server Health Monitoring";
                };
              }
              {
                "Dockhand" = {
                  icon = "https://cdn.jsdelivr.net/gh/selfhst/icons@main/png/dockhand.png";
                  href = "https://${subdomains.vm-monitor.dockhand}.${domain}";
                  description = "Container Management Dashboard";
                };
              }
              {
                "Beszel" = {
                  icon = "beszel";
                  href = "https://${subdomains.vm-monitor.beszel}.${domain}";
                  description = "Server Monitoring";
                };
              }
              {
                "Prometheus" = {
                  icon = "prometheus";
                  href = "https://${subdomains.vm-monitor.prometheus}.${domain}";
                  description = "Metrics Monitoring";
                };
              }
              {
                "Grafana" = {
                  icon = "grafana";
                  href = "https://${subdomains.vm-monitor.grafana}.${domain}";
                  description = "Metrics Visualization";
                };
              }
              {
                "Wazuh" = {
                  icon = "wazuh";
                  href = "https://${subdomains.vm-monitor.wazuh}.${domain}";
                  description = "Security Monitoring";
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
