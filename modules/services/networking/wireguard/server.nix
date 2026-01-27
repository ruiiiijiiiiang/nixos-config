{
  config,
  consts,
  lib,
  ...
}:
let
  inherit (import ../../../../lib/keys.nix) wg;
  inherit (consts) addresses ports;
  cfg = config.custom.services.networking.wireguard;
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

  config = lib.mkIf cfg.server.enable {
    assertions = [
      {
        assertion = cfg.server.privateKeyFile != null;
        message = "WireGuard server is enabled but required key is missing.";
      }
      {
        assertion = cfg.server.wanInterface != null && cfg.server.lanInterface != null;
        message = "Suricata is enabled but required interfaces are missing.";
      }
    ];

    networking = {
      wireguard.interfaces.${cfg.server.wgInterface} = {
        ips = [
          "${addresses.vpn.hosts.${config.networking.hostName}}/32"
        ];
        listenPort = ports.wireguard;
        inherit (cfg.server) privateKeyFile;

        peers = map (peer: {
          inherit (wg.${peer.hostName}) publicKey;
          inherit (peer) presharedKeyFile;
          allowedIPs = [ "${addresses.vpn.hosts.${peer.hostName}}/32" ];
        }) cfg.server.peers;
      };

      firewall.interfaces = {
        "${cfg.server.wanInterface}" = {
          allowedUDPPorts = [ ports.wireguard ];
        };

        "${cfg.server.lanInterface}" = {
          allowedUDPPorts = [ ports.wireguard ];
        };

        "${cfg.server.wgInterface}" = {
          allowedTCPPorts = [ ports.dns ];
          allowedUDPPorts = [ ports.dns ];
        };
      };
    };

    custom.services.networking.router.extraForwardRules = ''
      # VPN -> LAN
      iifname "${cfg.server.wgInterface}" oifname "${cfg.server.lanInterface}" accept

      # VPN -> Infra
      iifname "${cfg.server.wgInterface}" oifname "${cfg.server.infraInterface}" accept

      # VPN -> DMZ
      iifname "${cfg.server.wgInterface}" oifname "${cfg.server.dmzInterface}" accept
    '';
  };
}
