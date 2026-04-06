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
    domain
    subdomains
    ports
    oci-uids
    daily-tasks
    ;
  inherit (helpers) dailyTaskToSystemd mkVirtualHost;
  cfg = config.custom.services.infra.harmonia;
  fqdn = "${subdomains.${config.networking.hostName}.harmonia}.${domain}";

  hosts = [
    "framework"
    "hypervisor"
    "vm-network"
    "vm-app"
    "vm-monitor"
    "vm-cyber"
  ];
  gcRootStr = "/var/lib/nix-cache-roots";

  dailyBuildScript = pkgs.writeShellScriptBin "daily-nix-build" /* bash */ ''
    set -euo pipefail

    export PATH="${
      pkgs.lib.makeBinPath (
        with pkgs;
        [
          nix
          git
        ]
      )
    }:$PATH"

    nix flake update --no-warn-dirty --refresh

    for host in ${toString hosts}; do
      echo "=========================================="
      echo "Building system closure for: $host"
      echo "=========================================="
      nix build ".#nixosConfigurations.$host.config.system.build.toplevel" --no-warn-dirty --out-link "${gcRootStr}/$host" || true
    done
  '';
in
{
  options.custom.services.infra.harmonia = with lib; {
    enable = mkEnableOption "Enable Harmonia binary cache";
  };

  config = lib.mkIf cfg.enable {
    age.secrets = {
      harmonia-sign-key = {
        file = ../../../../secrets/harmonia-sign-key.age;
        mode = "440";
        owner = "harmonia";
        group = "harmonia";
      };
    };

    services = {
      harmonia = {
        cache = {
          enable = true;
          settings = {
            bind = "[::]:${toString ports.harmonia}";
            sign_key_path = config.age.secrets.harmonia-sign-key.path;
          };
        };
      };

      nginx.virtualHosts."${fqdn}" = mkVirtualHost {
        inherit fqdn;
        port = ports.harmonia;
      };
    };

    systemd = {
      tmpfiles.rules = [
        "d ${gcRootStr} 0755 ${toString oci-uids.user} ${toString oci-uids.user} - -"
        "L+ /nix/var/nix/gcroots/per-user/${username}/daily-builds - - - - ${gcRootStr}"
      ];

      timers.daily-nix-build = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = dailyTaskToSystemd daily-tasks.${config.networking.hostName}.nix-build;
          Unit = "daily-nix-build.service";
        };
      };

      services.daily-nix-build = {
        description = "Update flake.lock, build system";
        serviceConfig = {
          Type = "oneshot";
          User = username;
          WorkingDirectory = "${home}/nixos-config";
          ExecStart = "${dailyBuildScript}/bin/daily-nix-build";
        };
      };
    };
  };
}
