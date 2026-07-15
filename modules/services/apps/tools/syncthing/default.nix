{
  config,
  consts,
  helpers,
  lib,
  ...
}:
let
  inherit (consts)
    username
    home
    domain
    subdomains
    ports
    ;
  inherit (helpers) mkVirtualHost;
  cfg = config.custom.services.apps.tools.syncthing;
  fqdn =
    if cfg.proxied then "${subdomains.${config.networking.hostName}.syncthing}.${domain}" else "";
in
{
  options.custom.services.apps.tools.syncthing = with lib; {
    enable = mkEnableOption "Enable Syncthing";
    proxied = mkEnableOption "Enable Syncthing behind reverse proxy";
  };

  config = lib.mkIf cfg.enable {
    services = {
      syncthing = {
        enable = true;
        user = username;
        group = username;
        dataDir = "${home}/Syncthing";
        settings = {
          devices = {
            "desktop" = {
              id = "EXNOSMW-CCMVP5W-IH2UTQ6-OX6JUOF-5QTG6TF-T3MHVIF-6CIDQUX-QZZ6JAD";
            };
            "framework" = {
              id = "WCWDE6A-TKMGJSW-BGAQIPO-U23NZOW-MI7IXKX-6T65RK4-CAGQJ56-YWL3CQJ";
            };
            "vm-app" = {
              id = "TKAXHBY-LFRMNI5-NE4Z3GL-QCNH2ZY-KIVYTYI-LZPSQHN-4NIFJDC-6TPHFAI";
            };
            "windows" = {
              id = "A3QHGMY-JKQQREB-KZCSOHS-2N3IXTL-2WZ2TMV-MZRWGIN-BISZOYK-AQGQIAF";
            };
            "pixel-7" = {
              id = "AEIUHYY-ILD6DGM-M65BRTC-QLHS2KT-UVM46P5-QRYA3P2-57AZFBZ-R3S7EQX";
            };
          };

          folders = {
            "default" = {
              id = "default";
              path = "~/Sync";
              devices = [
                "desktop"
                "framework"
                "vm-app"
                "windows"
                "pixel-7"
              ];
            };
            "obsidian" = {
              id = "obsidian";
              path = "~/obsidian";
              devices = [
                "desktop"
                "framework"
                "vm-app"
                "windows"
                "pixel-7"
              ];
            };
            "dotfiles" = {
              id = "dotfiles";
              path = "~/dotfiles";
              devices = [
                "desktop"
                "framework"
                "vm-app"
                "windows"
              ];
            };
            "nixos-config" = {
              id = "nixos-config";
              path = "~/nixos-config";
              devices = [
                "desktop"
                "framework"
                "vm-app"
                "windows"
              ];
            };
          };

          gui = {
            address = "${domain}:${toString ports.syncthing}";
            insecureSkipHostcheck = true;
          };
        };
      };

      nginx.virtualHosts."${fqdn}" = lib.mkIf cfg.proxied (mkVirtualHost {
        inherit fqdn;
        port = ports.syncthing;
        extraConfig = "proxy_read_timeout 86400s;";
      });
    };
  };
}
