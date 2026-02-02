{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.roles.security.services;
in
{
  options.custom.roles.security.services = with lib; {
    enable = mkEnableOption "Security role services";
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
        package = pkgs.postgresql;
        authentication = pkgs.lib.mkForce ''
          local all all trust
          host all all 127.0.0.1/32 trust
          host all all ::1/128 trust
        '';
        initialScript = pkgs.writeText "backend-initScript" ''
          CREATE ROLE msf WITH LOGIN PASSWORD 'msf' CREATEDB;
          CREATE DATABASE msf OWNER msf;
        '';
      };

      vnstat.enable = true;

      xrdp = {
        enable = true;
        audio.enable = true;
        defaultWindowManager = "startlxqt";
      };
    };

    users.users.rui.extraGroups = [
      "audio"
      "pcap"
      "wireshark"
    ];
  };
}
