{
  config,
  consts,
  helpers,
  keys,
  lib,
  ...
}:
let
  inherit (helpers) getHostAddress;
  inherit (keys) wg;
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
            invalid = lib.filter (
              peer:
              !(lib.hasAttr peer.hostName wg) || !(lib.hasAttrByPath [ "wg" "hosts" peer.hostName ] addresses)
            ) cfg.peers;
          in
          invalid == [ ];
        message = "WireGuard server peers must exist in wg keys and addresses.wg.hosts.";
      }
      {
        assertion = lib.length cfg.peers == lib.length (lib.unique (map (peer: peer.hostName) cfg.peers));
        message = "WireGuard server peers must not contain duplicate hostName entries.";
      }
      {
        assertion =
          cfg.wanInterface != cfg.lanInterface
          && cfg.wgInterface != cfg.wanInterface
          && cfg.wgInterface != cfg.lanInterface;
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
          "${
            getHostAddress {
              inherit (config.networking) hostName;
              network = "wg";
            }
          }/32"
          "${
            getHostAddress {
              inherit (config.networking) hostName;
              network = "wg";
              isV6 = true;
            }
          }/128"
        ];
        listenPort = ports.wireguard;
        inherit (cfg) privateKeyFile;

        peers = map (peer: {
          inherit (wg.${peer.hostName}) publicKey;
          inherit (peer) presharedKeyFile;
          allowedIPs = [
            "${
              getHostAddress {
                inherit (peer) hostName;
                network = "wg";
              }
            }/32"
            "${
              getHostAddress {
                inherit (peer) hostName;
                network = "wg";
                isV6 = true;
              }
            }/128"
          ];
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
  };
}
