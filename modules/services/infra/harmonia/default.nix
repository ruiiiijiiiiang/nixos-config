{
  secretsDir,
  config,
  consts,
  helpers,
  lib,
  ...
}:
let
  inherit (consts)
    username
    domain
    subdomains
    ports
    oci-uids
    ;
  inherit (helpers) mkVirtualHost;
  cfg = config.custom.services.infra.harmonia;
  fqdn = "${subdomains.${config.networking.hostName}.harmonia}.${domain}";
  gcRoot = "/var/lib/nix-cache-roots";
in
{
  options.custom.services.infra.harmonia = with lib; {
    enable = mkEnableOption "Enable Harmonia binary cache";
  };

  config = lib.mkIf cfg.enable {
    age.secrets = {
      harmonia-sign-key = {
        file = secretsDir + "/infra/harmonia/signing-key.age";
        mode = "600";
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
            sign_key_paths = [ config.age.secrets.harmonia-sign-key.path ];
            priority = 10;
          };
        };
      };

      nginx.virtualHosts."${fqdn}" = mkVirtualHost {
        inherit fqdn;
        port = ports.harmonia;
        extraConfig = ''
          proxy_buffering off;
          proxy_max_temp_file_size 0;
        '';
      };
    };

    users.users.harmonia = {
      isSystemUser = true;
      group = "harmonia";
    };
    users.groups.harmonia = { };

    nix.settings = {
      keep-derivations = true;
      keep-outputs = true;
    };

    systemd = {
      tmpfiles.rules = [
        "d ${gcRoot} 0755 ${toString oci-uids.user} ${toString oci-uids.user} - -"
        "L+ /nix/var/nix/gcroots/per-user/${username}/daily-builds - - - - ${gcRoot}"
      ];
    };
  };
}
