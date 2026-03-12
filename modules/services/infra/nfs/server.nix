{
  config,
  consts,
  lib,
  ...
}:
let
  inherit (consts) addresses ports;
  cfg = config.custom.services.infra.nfs.server;

  commonOptions = "rw,nohide,insecure,no_subtree_check";
  networks = [
    "${addresses.home.network}/24"
    "${addresses.vpn.network}/24"
  ];
  exportLine = builtins.concatStringsSep " " (map (net: "${net}(${commonOptions})") networks);
in
{
  options.custom.services.infra.nfs.server = with lib; {
    enable = mkEnableOption "Enable NFS file server";
    interface = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Interface allowed to access file server.";
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
      if cfg.interface != null then
        {
          interfaces."${cfg.interface}".allowedTCPPorts = [ ports.nfs ];
        }
      else
        {
          allowedTCPPorts = [ ports.nfs ];
        };
  };
}
