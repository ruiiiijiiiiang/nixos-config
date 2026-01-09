{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.server.services;
in
{
  config = lib.mkIf cfg.enable {
    environment.variables = {
      EDITOR = lib.mkForce "vim";
    };

    virtualisation = {
      oci-containers = {
        backend = "podman";
      };
      podman = {
        enable = true;
        dockerCompat = true;
        dockerSocket.enable = true;
        autoPrune = {
          enable = true;
          dates = "weekly";
          flags = [ "--all" ];
        };
      };
    };

    systemd.timers.podman-auto-update = {
      wantedBy = [ "timers.target" ];
      enable = true;
    };

    systemd.tmpfiles.rules = [
      "L+ /var/run/docker.sock - - - - /run/podman/podman.sock"
    ];

    services = {
      logrotate.enable = true;
      journald.extraConfig = ''
        SystemMaxUse=1G
        Storage=persistent
      '';

      xserver.enable = false;
      avahi.enable = false;
      printing.enable = false;
    };

    environment.systemPackages = [
      inputs.agenix.packages.${pkgs.stdenv.system}.default
    ];
  };
}
