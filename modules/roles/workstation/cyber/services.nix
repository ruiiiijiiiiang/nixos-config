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
        videoDrivers = [ "modesetting" ];
      };

      pipewire.enable = false;

      pulseaudio = {
        enable = true;
        extraConfig = "load-module module-xrdp-sink";
      };

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

      xrdp = {
        enable = true;
        audio.enable = true;
        defaultWindowManager = "startlxqt";
      };
    };

    users.users.${username}.extraGroups = [
      "audio"
      "pcap"
      "wireshark"
    ];
  };
}
