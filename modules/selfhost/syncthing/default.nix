{ config, lib, ... }:
let
  inherit (lib) mkIf;
  inherit (import ../../../lib/consts.nix)
    addresses
    domains
    subdomains
    ports
    ;
  cfg = config.selfhost.syncthing;
  fqdn = "${subdomains.${config.networking.hostName}.syncthing}.${domains.home}";
in
{
  config = mkIf cfg.enable {
    services = {
      syncthing = {
        enable = true;
        user = "rui";
        group = "rui";
        dataDir = "/home/rui/Syncthing";
        settings = {
          devices = {
            "rui-arch" = {
              id = "DIKD4FJ-4SE2EKP-3Y23ROB-YAKQJP7-KHN2GRN-CTHD2OF-ECAXI3P-JGSYFQM";
            };
            "framework" = {
              id = "WCWDE6A-TKMGJSW-BGAQIPO-U23NZOW-MI7IXKX-6T65RK4-CAGQJ56-YWL3CQJ";
            };
            "vm-app" = {
              id = "TKAXHBY-LFRMNI5-NE4Z3GL-QCNH2ZY-KIVYTYI-LZPSQHN-4NIFJDC-6TPHFAI";
            };
            "Rui-Desktop" = {
              id = "A3QHGMY-JKQQREB-KZCSOHS-2N3IXTL-2WZ2TMV-MZRWGIN-BISZOYK-AQGQIAF";
            };
          };

          folders = {
            "default" = {
              id = "default";
              path = "~/Sync";
              devices = [
                "rui-arch"
                "framework"
                "vm-app"
                "Rui-Desktop"
              ];
            };
            "dotfiles" = {
              id = "dotfiles";
              path = "~/dotfiles";
              devices = [
                "rui-arch"
                "framework"
                "vm-app"
              ];
            };
            "nixos-config" = {
              id = "nixos-config";
              path = "~/nixos-config";
              devices = [
                "rui-arch"
                "framework"
                "vm-app"
              ];
            };
          };

          gui = {
            address = "${domains.home}:${toString ports.syncthing}";
            insecureSkipHostcheck = true;
          };
        };
      };

      nginx.virtualHosts."${fqdn}" = mkIf cfg.proxied {
        useACMEHost = fqdn;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://${addresses.localhost}:${toString ports.syncthing}";
        };
      };
    };
  };
}
