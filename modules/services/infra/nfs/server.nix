{
  config,
  consts,
  lib,
  ...
}:
let
  inherit (consts) addresses ports;
  cfg = config.custom.services.infra.nfs.server;

  commonOptions = "rw,nohide,insecure,no_subtree_check,no_root_squash,fsid=0";
  networks = [
    addresses.home.network
    addresses.vpn.network
  ];
  exportLine = builtins.concatStringsSep " " (map (net: "${net}(${commonOptions})") networks);
in
{
  options.custom.services.infra.nfs.server = with lib; {
    enable = mkEnableOption "Enable NFS file server";
    interfaces = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Interfaces allowed to access file server.";
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
