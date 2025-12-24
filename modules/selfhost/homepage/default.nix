{ config, lib, ... }:
with lib;
let
  consts = import ../../../lib/consts.nix;
  cfg = config.selfhost.homepage;
  fqdn = "${consts.subdomains.${config.networking.hostName}.homepage}.${consts.domains.home}";
in
with consts;
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
            "Tools" = {
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
            "Tools" = [
              {
                "Home Assistant" = {
                  icon = "home-assistant";
                  href = "https://ha.${domains.home}";
                  description = "Home Automation System";
                };
              }
              {
                "Bentopdf" = {
                  icon = "bentopdf";
                  href = "https://pdf.${domains.home}";
                  description = "PDF Tool";
                };
              }
              {
                "Dawarich" = {
                  icon = "dawarich";
                  href = "https://gps.${domains.home}";
                  description = "Location Tracking";
                };
              }
              {
                "Microbin" = {
                  icon = "microbin";
                  href = "https://bin.${domains.home}";
                  description = "Pastebin";
                };
              }
              {
                "Immich" = {
                  icon = "immich";
                  href = "https://immich.${domains.home}";
                  description = "Photos & Video";
                };
              }
              {
                "Paperless" = {
                  icon = "paperless";
                  href = "https://paperless.${domains.home}";
                  description = "Document Archive";
                };
              }
              {
                "Vaultwarden" = {
                  icon = "vaultwarden";
                  href = "https://vault.${domains.home}";
                  description = "Password Manager";
                };
              }
              {
                "Yourls" = {
                  icon = "yourls";
                  href = "https://url.${domains.home}/admin";
                  description = "URL Shortener";
                };
              }
              {
                "Calendar Parser" = {
                  icon = "p-cal";
                  href = "https://calendar-parse.ruiiiijiiiiang.deno.net";
                  description = "Parse CSV calendar from Pam's boss";
                };
              }
              {
                "Blog" = {
                  icon = "booklogr";
                  href = "https://public.ruijiang.me/blog/0";
                  description = "Rui's blog";
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
                  href = "https://portainer.${domains.home}";
                  description = "Container Dashboard";
                };
              }
              {
                "Syncthing" = {
                  icon = "syncthing";
                  href = "https://syncthing.${domains.home}";
                  description = "File Sync Tool";
                };
              }
              {
                "Zwave" = {
                  icon = "z-wave-js-ui";
                  href = "https://zwave.${domains.home}";
                  description = "Zwave Device Manager";
                };
              }
              {
                "Pihole" = {
                  icon = "pi-hole";
                  href = "https://pihole.${domains.home}";
                  description = "DNS Ad Blocker";
                };
              }
              {
                "Pihole Backup 1" = {
                  icon = "pi-hole";
                  href = "https://pi-pihole.${domains.home}";
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

      nginx.virtualHosts."${fqdn}" = {
        useACMEHost = fqdn;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://${addresses.localhost}:${toString ports.homepage}";
        };
      };
    };
  };
  # systemd.services.homepage-dashboard.serviceConfig.EnvironmentFile =
  #   "/var/lib/homepage-dashboard/.env";
}
