{
  config,
  consts,
  lib,
  pkgs,
  helpers,
  inputs,
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
    endpoints
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
  gcRoot = "/var/lib/nix-cache-roots";
  ntfyEnabled = inputs.self.nixosConfigurations.vm-monitor.config.custom.observability.ntfy.enable;

  dailyNixBuildScriptText =
    lib.replaceStrings
      [
        "@HOME@"
        "@HOSTS@"
        "@GC_ROOT@"
        "@NTFY_SERVER@"
        "@NTFY_ENABLED@"
      ]
      [
        (lib.escapeShellArg home)
        (lib.concatMapStringsSep " " lib.escapeShellArg hosts)
        (lib.escapeShellArg gcRoot)
        (lib.escapeShellArg endpoints.ntfy-server)
        (lib.escapeShellArg (lib.boolToString ntfyEnabled))
      ]
      (lib.readFile ./daily-nix-build.sh);

  dailyNixBuildScript = pkgs.writeShellApplication {
    name = "daily-nix-build";
    runtimeInputs = with pkgs; [
      curl
      nix
      git
    ];
    text = dailyNixBuildScriptText;
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
        "d ${gcRoot} 0755 ${toString oci-uids.user} ${toString oci-uids.user} - -"
        "L+ /nix/var/nix/gcroots/per-user/${username}/daily-builds - - - - ${gcRoot}"
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
