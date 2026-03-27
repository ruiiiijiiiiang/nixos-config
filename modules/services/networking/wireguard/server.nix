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
    enable = mkEnableOption "Enable WireGuard server";
    privateKeyFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "WireGuard server private key path.";
    };
    wanInterface = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "WAN interface name.";
    };
    lanInterface = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "LAN interface name.";
    };
    infraInterface = mkOption {
      type = types.str;
      default = "infra0";
      description = "Infra VLAN interface name.";
    };
    dmzInterface = mkOption {
      type = types.str;
      default = "dmz0";
      description = "DMZ VLAN interface name.";
    };
    wgInterface = mkOption {
      type = types.str;
      default = "wg0";
      description = "WireGuard interface name.";
    };

    peers = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            hostName = mkOption {
              type = types.str;
              description = "Peer hostname.";
            };
            presharedKeyFile = mkOption {
              type = types.path;
              description = "Preshared key path.";
            };
          };
        }
      );
      default = [ ];
      description = "WireGuard peers.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.privateKeyFile != null;
        message = "WireGuard server requires privateKeyFile.";
      }
      {
        assertion = cfg.wanInterface != null && cfg.lanInterface != null;
        message = "WireGuard server requires WAN and LAN interfaces.";
      }
      {
        assertion =
          let
            invalid = builtins.filter (
              peer: !(builtins.hasAttr peer.hostName wg) || !(builtins.hasAttr peer.hostName addresses.vpn.hosts)
            ) cfg.peers;
          in
          invalid == [ ];
        message = "WireGuard server peers must exist in wg keys and addresses.vpn.hosts.";
      }
      {
        assertion = lib.length cfg.peers == lib.length (lib.unique (map (peer: peer.hostName) cfg.peers));
        message = "WireGuard server peers must not contain duplicate hostName entries.";
      }
      {
        assertion =
          cfg.wanInterface != cfg.lanInterface
          && cfg.wgInterface != cfg.wanInterface
          && cfg.wgInterface != cfg.lanInterface
          && cfg.infraInterface != cfg.dmzInterface;
        message = "WireGuard server interface names must not overlap.";
      }
      {
        assertion = config.custom.services.networking.router.enable;
        message = "WireGuard server requires networking.router.enable for forwarding rules.";
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

    custom.services.networking.router.extraForwardRules = /* bash */ ''
      iifname "${cfg.wgInterface}" oifname "${cfg.lanInterface}" accept
      iifname "${cfg.wgInterface}" oifname "${cfg.infraInterface}" accept
      iifname "${cfg.wgInterface}" oifname "${cfg.dmzInterface}" accept
    '';
  };
}
