{
  config,
  consts,
  lib,
  pkgs,
  helpers,
  ...
}:
let
  inherit (consts)
    username
    home
    domains
    subdomains
    ports
    oci-uids
    ;
  inherit (helpers) mkVirtualHost;
  cfg = config.custom.services.apps.tools.harmonia;
  fqdn = "${subdomains.${config.networking.hostName}.harmonia}.${domains.home}";
  hostsToBuild = [
    "framework"
    "vm-network"
    "vm-app"
    "vm-monitor"
    "vm-cyber"
    "pi"
  ];
  gcRootStr = "/var/lib/nix-cache-roots";
in
{
  options.custom.services.apps.tools.harmonia = with lib; {
    enable = mkEnableOption "Harmonia nix binary cache";
  };

  config = lib.mkIf cfg.enable {
    age.secrets = {
      harmonia = {
        file = ../../../../../secrets/harmonia.age;
        mode = "440";
        owner = "harmonia";
        group = "harmonia";
      };
    };

    services = {
      harmonia = {
        enable = true;
        settings = {
          bind = "[::]:${toString ports.harmonia}";
          sign_key_path = config.age.secrets.harmonia.path;
        };
      };

      nginx.virtualHosts."${fqdn}" = mkVirtualHost {
        inherit fqdn;
        port = ports.harmonia;
      };
    };

    boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

    systemd = {
      tmpfiles.rules = [
        "d ${gcRootStr} 0755 ${toString oci-uids.user} ${toString oci-uids.user} - -"
        "L+ /nix/var/nix/gcroots/per-user/rui/daily-builds - - - - ${gcRootStr}"
      ];

      timers.daily-nix-build = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "04:00:00";
          Persistent = true;
          Unit = "daily-nix-build.service";
        };
      };

      services.daily-nix-build = {
        description = "Update flake.lock, build system";
        serviceConfig = {
          Type = "oneshot";
          User = username;
          WorkingDirectory = "${home}/nixos-config";
        };

        path = with pkgs; [ nix git ];

        script = ''
          set -e
          nix flake update

          for host in ${toString hostsToBuild}; do
            echo "=========================================="
            echo "Building system closure for: $host"
            echo "=========================================="
            nix build ".#nixosConfigurations.$host.config.system.build.toplevel" --out-link "${gcRootStr}/$host"
          done
        '';
      };
    };
  };
}
