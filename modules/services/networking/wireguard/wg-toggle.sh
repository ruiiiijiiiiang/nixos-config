#!/usr/bin/env bash

# NetworkManager dispatcher script to toggle WireGuard profile based on Wi-Fi connection security.
# Can also be run manually.

log() {
  echo "$1"
  logger -t wg-toggle "$1"
}

if [ "$#" -lt 2 ]; then
  echo "Usage: wg-toggle <interface> <action> [connection_uuid]" >&2
  echo "  interface: Network interface (e.g. wlan0)" >&2
  echo "  action:    'up' or 'down'" >&2
  exit 1
fi

INTERFACE="$1"
ACTION="$2"
CONNECTION_UUID="${3:-}"

DEV_TYPE=$(nmcli -g GENERAL.TYPE device show "$INTERFACE" 2>/dev/null || true)

if [ "$DEV_TYPE" != "wifi" ]; then
  # If run manually in a terminal, print a debug message.
  if [ -t 1 ]; then
    echo "Interface '$INTERFACE' is not a Wi-Fi interface (type: '$DEV_TYPE'). Nothing to do."
  fi
  exit 0
fi

if [ "$ACTION" = "up" ]; then
  IP_METHOD=""
  if [ -n "$CONNECTION_UUID" ]; then
    IP_METHOD=$(nmcli -g ipv4.method connection show "$CONNECTION_UUID" 2>/dev/null || true)
  fi

  SEC=$(nmcli -t -f ACTIVE,SECURITY dev wifi | grep '^yes:' | cut -d: -f2 || true)

  if [ "$IP_METHOD" = "manual" ]; then
    log "Connected to Home Wi-Fi (Static IP). Stopping VPNs..."
    systemctl stop wg-quick-@WG_INTERFACE@-split.service wg-quick-@WG_INTERFACE@-full.service
  elif [ -z "$SEC" ] || [ "$SEC" = "--" ]; then
    log "Connected to OPEN Wi-Fi. Activating full-tunnel VPN..."
    systemctl stop wg-quick-@WG_INTERFACE@-split.service
    systemctl start wg-quick-@WG_INTERFACE@-full.service
  else
    log "Connected to SECURE Wi-Fi. Activating split-tunnel VPN..."
    systemctl stop wg-quick-@WG_INTERFACE@-full.service
    systemctl start wg-quick-@WG_INTERFACE@-split.service
  fi
elif [ "$ACTION" = "down" ]; then
  log "Wi-Fi disconnected. Stopping VPNs..."
  systemctl stop wg-quick-@WG_INTERFACE@-split.service wg-quick-@WG_INTERFACE@-full.service
else
  echo "Error: Unknown action '$ACTION'. Supported actions: up, down." >&2
  exit 1
fi
