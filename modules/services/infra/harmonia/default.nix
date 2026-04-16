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
    "vm-public"
    "vm-cyber"
  ];
  gcRootStr = "/var/lib/nix-cache-roots";

  dailyNixBuildScript = pkgs.writeShellApplication {
    name = "daily-nix-build";
    runtimeInputs = with pkgs; [
      nix
      git
    ];
    text = /* bash */ ''
      CPT_DEB="${home}/Sync/CiscoPacketTracer_900_Ubuntu_64bit.deb"
      if [ -f "$CPT_DEB" ]; then
        echo "Ensuring Cisco Packet Tracer is in store..."
        nix-store --add-fixed sha256 "$CPT_DEB" > /dev/null
      fi

      nix flake update --no-warn-dirty --refresh

      for host in ${toString hosts}; do
        echo "=========================================="
        echo "Building system closure for: $host"
        echo "=========================================="

        nix build ".#nixosConfigurations.$host.config.system.build.toplevel" \
          --no-warn-dirty \
          --out-link "${gcRootStr}/$host" || true
      done
    '';
  };
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

    nix.settings = {
      keep-derivations = true;
      keep-outputs = true;
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
          ExecStart = "${dailyNixBuildScript}/bin/daily-nix-build";
        };
      };
    };
  };
}
