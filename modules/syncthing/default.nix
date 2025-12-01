{ config, lib, ... }:
with lib;
let
  cfg = config.rui.syncthing;
  consts = import ../../lib/consts.nix;
in with consts; {
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
            "rui-nixos" = {
              id = "WCWDE6A-TKMGJSW-BGAQIPO-U23NZOW-MI7IXKX-6T65RK4-CAGQJ56-YWL3CQJ";
            };
            "rui-nixos-pi" = {
              id = "NXD67VO-TJMXS4M-D2Q7OH4-RXP7G5B-LU3X2HE-AGMLZHT-JWCKQFW-7B746AM";
            };
            "Rui-Desktop" = {
              id = "A3QHGMY-JKQQREB-KZCSOHS-2N3IXTL-2WZ2TMV-MZRWGIN-BISZOYK-AQGQIAF";
            };
          };

          folders = {
            "default" = {
              id = "default";
              path = "~/Sync";
              devices = [ "rui-arch" "rui-nixos" "rui-nixos-pi" "Rui-Desktop" ];
            };
            "dotfiles" = {
              id = "dotfiles";
              path = "~/dotfiles";
              devices = [ "rui-arch" "rui-nixos" "rui-nixos-pi" ];
            };
          };

          gui = {
            address = "${domains.home}:${toString ports.syncthing}";
            insecureSkipHostcheck = true;
          };
        };
      };

      nginx.virtualHosts."syncthing.${domains.home}" = mkIf cfg.proxied {
        useACMEHost = domains.home;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://${addresses.localhost}:${toString ports.syncthing}";
        };
      };
    };
  };
}
