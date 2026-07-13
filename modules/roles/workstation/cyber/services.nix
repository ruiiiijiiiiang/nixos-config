{
  config,
  consts,
  lib,
  pkgs,
  ...
}:
let
  inherit (consts) username;
  cfg = config.custom.roles.workstation.cyber.services;
in
{
  options.custom.roles.workstation.cyber.services = with lib; {
    enable = mkEnableOption "Enable cyber role services";
  };

  config = lib.mkIf cfg.enable {
    services = {
      xserver = {
        enable = true;
        displayManager.lightdm.enable = true;
        desktopManager.lxqt.enable = true;
      };

      pipewire.enable = false;
      pulseaudio.enable = true;

      postgresql = {
        enable = true;
        ensureDatabases = [ "msf" ];
        ensureUsers = [
          {
            name = "msf";
            ensureDBOwnership = true;
          }
        ];
        identMap = ''
          msf_map ${username} msf
        '';
        authentication = pkgs.lib.mkOverride 10 ''
          local all all peer map=msf_map
        '';
      };

      vnstat.enable = true;
    };

    xdg.portal = {
      enable = true;
      config.common.default = [ "gtk" ];
      extraPortals = [
        pkgs.xdg-desktop-portal-gtk
      ];
    };

    environment.etc.hosts.mode = "0644";

    users.users.${username}.extraGroups = [
      "audio"
      "pcap"
      "wireshark"
    ];
  };
}
