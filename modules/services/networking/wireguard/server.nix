{
  config,
  consts,
  lib,
  ...
}:
let
  inherit (import ../../../../lib/keys.nix) wg;
  inherit (consts) addresses ports;
  cfg = config.custom.services.networking.wireguard.server;
in
{
  options.custom.services.networking.wireguard.server = with lib; {
    enable = mkEnableOption "WireGuard VPN server";
    privateKeyFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to WireGuard server private key";
    };
    wanInterface = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Interface for WAN";
    };
    lanInterface = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Interface for LAN";
    };
    infraInterface = mkOption {
      type = types.str;
      default = "infra0";
      description = "Interface for infra VLAN";
    };
    dmzInterface = mkOption {
      type = types.str;
      default = "dmz0";
      description = "Interface for DMZ VLAN";
    };
    wgInterface = mkOption {
      type = types.str;
      default = "wg0";
      description = "Interface for WireGuard server";
    };

    peers = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            hostName = mkOption {
              type = types.str;
              description = "Hostname of the peer";
            };
            presharedKeyFile = mkOption {
              type = types.path;
              description = "Path to the preshared key file";
            };
          };
        }
      );
      default = [ ];
      description = "List of WireGuard peers";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.privateKeyFile != null;
        message = "WireGuard server is enabled but required key is missing.";
      }
      {
        assertion = cfg.wanInterface != null && cfg.lanInterface != null;
        message = "WireGuard server is enabled but required interfaces are missing.";
      }
    ];

    networking = {
      wireguard.interfaces.${cfg.wgInterface} = {
        ips = [
          "${addresses.vpn.hosts.${config.networking.hostName}}/32"
        ];
        listenPort = ports.wireguard;
        inherit (cfg) privateKeyFile;

        peers = map (peer: {
          inherit (wg.${peer.hostName}) publicKey;
          inherit (peer) presharedKeyFile;
          allowedIPs = [ "${addresses.vpn.hosts.${peer.hostName}}/32" ];
        }) cfg.peers;
      };

      firewall.interfaces = {
        "${cfg.wanInterface}" = {
          allowedUDPPorts = [ ports.wireguard ];
        };

        "${cfg.lanInterface}" = {
          allowedUDPPorts = [ ports.wireguard ];
        };

        "${cfg.wgInterface}" = {
          allowedTCPPorts = [ ports.dns ];
          allowedUDPPorts = [ ports.dns ];
        };
      };
    };

    custom.services.networking.router.extraForwardRules = ''
      iifname "${cfg.wgInterface}" oifname "${cfg.lanInterface}" accept
      iifname "${cfg.wgInterface}" oifname "${cfg.infraInterface}" accept
      iifname "${cfg.wgInterface}" oifname "${cfg.dmzInterface}" accept
    '';
  };
}
