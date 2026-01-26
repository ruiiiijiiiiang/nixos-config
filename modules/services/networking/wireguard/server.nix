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
    wgInterface = mkOption {
      type = types.str;
      default = "wg0";
      description = "Interface for WireGuard server";
    };
    lanInterface = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Interface for LAN";
    };
    infraInterface = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Interface for infra VLAN";
    };
    dmzInterface = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Interface for DMZ VLAN";
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

      nat = {
        internalInterfaces = [ cfg.server.wgInterface ];
      };

      firewall = {
        trustedInterfaces = [ cfg.server.wgInterface ];
        allowedUDPPorts = [ ports.wireguard ];
      };
    };

    custom.services.networking.router.extraForwardRules = ''
      # VPN -> LAN
      ${
        lib.optionalString cfg.server.lanInterface != null ''
          iifname "${cfg.server.wgInterface}" oifname "${cfg.server.lanInterface}" accept
        ''
      }

      # VPN -> Infra
      ${
        lib.optionalString cfg.server.infraInterface != null ''
          iifname "${cfg.server.wgInterface}" oifname "${cfg.server.infraInterface}" accept
        ''
      }

      # VPN -> DMZ
      ${
        lib.optionalString cfg.server.dmzInterface != null ''
          iifname "${cfg.server.wgInterface}" oifname "${cfg.server.dmzInterface}" accept
        ''
      }
    '';
  };
}
