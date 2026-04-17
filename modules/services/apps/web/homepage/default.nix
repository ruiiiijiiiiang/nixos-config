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
  inherit (helpers) getHostAddress mkVirtualHost;
  cfg = config.custom.services.apps.web.homepage;
  fqdn = "${subdomains.${config.networking.hostName}.homepage}.${domain}";
in
{
  options.custom.services.apps.web.homepage = with lib; {
    enable = mkEnableOption "Enable Homepage dashboard";
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
              "Authentication" = {
                style = "row";
                columns = 6;
                tab = "Apps";
              };
            }
            {
              "External" = {
                style = "row";
                columns = 6;
                tab = "Apps";
                iconsOnly = true;
              };
            }
            {
              "Development" = {
                style = "row";
                columns = 6;
                tab = "Homelab";
              };
            }
            {
              "Downloads" = {
                style = "row";
                columns = 6;
                tab = "Homelab";
              };
            }
            {
              "Networking" = {
                style = "row";
                columns = 6;
                tab = "Homelab";
              };
            }
            {
              "System" = {
                style = "row";
                columns = 6;
                tab = "Homelab";
              };
            }
            {
              "Security" = {
                style = "row";
                columns = 6;
                tab = "Homelab";
              };
            }
          ];
        };

        widgets = [
          {
            datetime = {
              text_size = "xl";
              format = {
                dateStyle = "short";
                timeStyle = "short";
                hour12 = true;
              };
            };
          }
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
                  siteMonitor = "https://${subdomains.vm-app.immich}.${domain}";
                };
              }
              {
                "Jellyfin" = {
                  icon = "jellyfin";
                  href = "https://${subdomains.vm-app.jellyfin}.${domain}";
                  description = "Media Server";
                  siteMonitor = "https://${subdomains.vm-app.jellyfin}.${domain}";
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
                  siteMonitor = "https://${subdomains.vm-app.bytestash}.${domain}";
                };
              }
              {
                "Forgejo" = {
                  icon = "forgejo";
                  href = "https://${subdomains.vm-app.forgejo}.${domain}";
                  description = "Version Control";
                  siteMonitor = "https://${subdomains.vm-app.forgejo}.${domain}";
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
                  siteMonitor = "https://${subdomains.vm-app.sonarr}.${domain}";
                };
              }
              {
                "Radarr" = {
                  icon = "radarr";
                  href = "https://${subdomains.vm-app.radarr}.${domain}";
                  description = "Movie Management";
                  siteMonitor = "https://${subdomains.vm-app.radarr}.${domain}";
                };
              }
              {
                "Lidarr" = {
                  icon = "lidarr";
                  href = "https://${subdomains.vm-app.lidarr}.${domain}";
                  description = "Music Management";
                  siteMonitor = "https://${subdomains.vm-app.lidarr}.${domain}";
                };
              }
              {
                "Prowlarr" = {
                  icon = "prowlarr";
                  href = "https://${subdomains.vm-app.prowlarr}.${domain}";
                  description = "Indexer Management";
                  siteMonitor = "https://${subdomains.vm-app.prowlarr}.${domain}";
                };
              }
              {
                "Bazarr" = {
                  icon = "bazarr";
                  href = "https://${subdomains.vm-app.bazarr}.${domain}";
                  description = "Subtitle Management";
                  siteMonitor = "https://${subdomains.vm-app.bazarr}.${domain}";
                };
              }
              {
                "qBittorrent" = {
                  icon = "qbittorrent";
                  href = "https://${subdomains.vm-app.qbittorrent}.${domain}";
                  description = "Torrent Client";
                  siteMonitor = "https://${subdomains.vm-app.qbittorrent}.${domain}";
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
                  siteMonitor = "https://${subdomains.vm-app.opencloud}.${domain}";
                };
              }
              {
                "Paperless" = {
                  icon = "paperless";
                  href = "https://${subdomains.vm-app.paperless}.${domain}";
                  description = "Document Archive";
                  siteMonitor = "https://${subdomains.vm-app.paperless}.${domain}";
                };
              }
              {
                "Memos" = {
                  icon = "memos";
                  href = "https://${subdomains.vm-app.memos}.${domain}";
                  description = "Note Taking";
                  siteMonitor = "https://${subdomains.vm-app.memos}.${domain}";
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
                  siteMonitor = "https://${subdomains.vm-app.pocketid}.${domain}";
                };
              }
              {
                "Vaultwarden" = {
                  icon = "vaultwarden";
                  href = "https://${subdomains.vm-app.vaultwarden}.${domain}";
                  description = "Password Manager";
                  siteMonitor = "https://${subdomains.vm-app.vaultwarden}.${domain}";
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
                  description = "Home Automation";
                  siteMonitor = "https://${subdomains.pi.homeassistant}.${domain}";
                };
              }
              {
                "Microbin" = {
                  icon = "microbin";
                  href = "https://${subdomains.vm-public.microbin}.${domain}";
                  description = "Pastebin";
                  siteMonitor = "https://${subdomains.vm-public.microbin}.${domain}";
                };
              }
              {
                "Karakeep" = {
                  icon = "karakeep";
                  href = "https://${subdomains.vm-app.karakeep}.${domain}";
                  description = "Bookmark";
                  siteMonitor = "https://${subdomains.vm-app.karakeep}.${domain}";
                };
              }
              {
                "Librechat" = {
                  icon = "librechat";
                  href = "https://${subdomains.vm-app.librechat}.${domain}";
                  description = "Chatbot";
                  siteMonitor = "https://${subdomains.vm-app.librechat}.${domain}";
                };
              }
              {
                "Reitti" = {
                  icon = "https://cdn.jsdelivr.net/gh/selfhst/icons@main/png/reitti.png";
                  href = "https://${subdomains.vm-app.reitti}.${domain}";
                  description = "Location Tracking";
                  siteMonitor = "https://${subdomains.vm-app.reitti}.${domain}";
                };
              }
              {
                "SearXNG" = {
                  icon = "searxng";
                  href = "https://${subdomains.vm-public.searxng}.${domain}";
                  description = "Search engine";
                  siteMonitor = "https://${subdomains.vm-public.searxng}.${domain}";
                };
              }
              {
                "Ovumcy" = {
                  icon = "https://raw.githubusercontent.com/ovumcy/ovumcy-web/refs/heads/main/web/static/brand/ovumcy-icon-dark.svg";
                  href = "https://${subdomains.vm-app.ovumcy}.${domain}";
                  description = "Ovumcy Web";
                  siteMonitor = "https://${subdomains.vm-app.ovumcy}.${domain}";
                };
              }
              {
                "ChangeDetection" = {
                  icon = "changedetection";
                  href = "https://${subdomains.vm-app.changedetection}.${domain}";
                  description = "Website Change Monitoring";
                  siteMonitor = "https://${subdomains.vm-app.changedetection}.${domain}";
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
                  siteMonitor = "https://${subdomains.vm-monitor.myspeed}.${domain}";
                };
              }
              {
                "Pihole" = {
                  icon = "pi-hole";
                  href = "https://${subdomains.vm-network.pihole}.${domain}";
                  description = "DNS Ad Blocker";
                  siteMonitor = "https://${subdomains.vm-network.pihole}.${domain}";
                };
              }
              {
                "Pihole Backup 1" = {
                  icon = "pi-hole";
                  href = "https://${subdomains.pi.pihole}.${domain}";
                  description = "DNS Ad Blocker";
                  siteMonitor = "https://${subdomains.pi.pihole}.${domain}";
                };
              }
              {
                "Pihole Backup 2" = {
                  icon = "pi-hole";
                  href = "https://${getHostAddress "pi-legacy"}/admin";
                  description = "DNS Ad Blocker";
                  siteMonitor = "https://${getHostAddress "pi-legacy"}/admin";
                };
              }
            ];
          }
          {
            "System" = [
              {
                "Cockpit" = {
                  icon = "cockpit";
                  href = "https://${subdomains.hypervisor.cockpit}.${domain}";
                  description = "Cockpit Server Manager";
                  siteMonitor = "https://${subdomains.hypervisor.cockpit}.${domain}";
                };
              }
              {
                "Termix" = {
                  icon = "termix";
                  href = "https://${subdomains.vm-monitor.termix}.${domain}";
                  description = "Web SSH";
                  siteMonitor = "https://${subdomains.vm-monitor.termix}.${domain}";
                };
              }
              {
                "Gatus" = {
                  icon = "gatus";
                  href = "https://${subdomains.vm-monitor.gatus}.${domain}";
                  description = "Server Health Monitoring";
                  siteMonitor = "https://${subdomains.vm-monitor.gatus}.${domain}";
                };
              }
              {
                "Dockhand" = {
                  icon = "https://cdn.jsdelivr.net/gh/selfhst/icons@main/png/dockhand.png";
                  href = "https://${subdomains.vm-monitor.dockhand}.${domain}";
                  description = "Container Management Dashboard";
                  siteMonitor = "https://${subdomains.vm-monitor.dockhand}.${domain}";
                };
              }
              {
                "Beszel" = {
                  icon = "beszel";
                  href = "https://${subdomains.vm-monitor.beszel}.${domain}";
                  description = "Server Monitoring";
                  siteMonitor = "https://${subdomains.vm-monitor.beszel}.${domain}";
                };
              }
              {
                "Prometheus" = {
                  icon = "prometheus";
                  href = "https://${subdomains.vm-monitor.prometheus}.${domain}";
                  description = "Metrics Monitoring";
                  siteMonitor = "https://${subdomains.vm-monitor.prometheus}.${domain}";
                };
              }
              {
                "Grafana" = {
                  icon = "grafana";
                  href = "https://${subdomains.vm-monitor.grafana}.${domain}";
                  description = "Metrics Visualization";
                  siteMonitor = "https://${subdomains.vm-monitor.grafana}.${domain}";
                };
              }
              {
                "Syncthing" = {
                  icon = "syncthing";
                  href = "https://${subdomains.vm-app.syncthing}.${domain}";
                  description = "File Sync Tool";
                  siteMonitor = "https://${subdomains.vm-app.syncthing}.${domain}";
                };
              }
              {
                "Zwave" = {
                  icon = "z-wave-js-ui";
                  href = "https://${subdomains.pi.zwave}.${domain}";
                  description = "Zwave Device Manager";
                  siteMonitor = "https://${subdomains.pi.zwave}.${domain}";
                };
              }
            ];
          }
          {
            "Security" = [
              {
                "Wazuh" = {
                  icon = "wazuh";
                  href = "https://${subdomains.vm-monitor.wazuh}.${domain}";
                  description = "Security Monitoring";
                  siteMonitor = "https://${subdomains.vm-monitor.wazuh}.${domain}";
                };
              }
              {
                "Krawl" = {
                  icon = "https://raw.githubusercontent.com/BlessedRebuS/Krawl/refs/heads/main/img/krawl-svg.svg";
                  href = "https://${subdomains.vm-public.krawl}.${domain}/krawl-honeypot-dashboard";
                  description = "Honeypot Dashboard";
                  siteMonitor = "https://${subdomains.vm-public.krawl}.${domain}/krawl-honeypot-dashboard";
                };
              }
            ];
          }
        ];

        bookmarks = [
          {
            "External" = [
              {
                "Calendar Parser" = [
                  {
                    icon = "p-cal";
                    href = "https://calendar-parse.ruiiiijiiiiang.deno.net";
                    description = "Parse CSV Calendar";
                  }
                ];
              }
              {
                "Bento PDF" = [
                  {
                    icon = "bentopdf";
                    href = "https://www.bentopdf.com";
                    description = "PDF Editor";
                  }
                ];
              }
              {
                "OmniTools" = [
                  {
                    icon = "omni-tools";
                    href = "https://omnitools.app";
                    description = "Miscellaneous Utilities";
                  }
                ];
              }
              {
                "Vert" = [
                  {
                    icon = "https://avatars.githubusercontent.com/u/198117259?s=48&v=4";
                    href = "https://vert.sh";
                    description = "File Converter";
                  }
                ];
              }
              {
                "IT Tools" = [
                  {
                    icon = "it-tools";
                    href = "https://it-tools.tech";
                    description = "IT Utilities";
                  }
                ];
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
