{
  config,
  consts,
  helpers,
  lib,
  ...
}:
let
  inherit (consts) ports;
  inherit (helpers) getHostAddress;
  cfg = config.custom.services.infra.nfs.server;

  commonOptions = "rw,nohide,no_subtree_check,fsid=0";
  exportLine = lib.concatStringsSep " " (map (net: "${net}(${commonOptions})") cfg.allowedHosts);
in
{
  options.custom.services.infra.nfs.server = with lib; {
    enable = mkEnableOption "Enable NFS file server";
    interfaces = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Interfaces allowed to access file server.";
    };
    allowedHosts = mkOption {
      type = types.listOf types.str;
      default = [
        (getHostAddress "framework")
        (getHostAddress "arch")
        (getHostAddress {
          hostName = "framework";
          isV6 = true;
        })
        (getHostAddress {
          hostName = "arch";
          isV6 = true;
        })
      ];
      description = "Hosts allowed to access file server.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.nfs.server = {
      enable = true;
      exports = ''
        / ${exportLine}
      '';
    };

    networking.firewall =
      if cfg.interfaces != [ ] then
        {
          interfaces = lib.genAttrs cfg.interfaces (iface: {
            allowedTCPPorts = [
              ports.nfs
            ];
          });
        }
      else
        {
          allowedTCPPorts = [ ports.nfs ];
        };
  };
}
