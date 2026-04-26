readonly HOME_DIR=@HOME@
readonly GC_ROOT=@GC_ROOT@
readonly NTFY_SERVER=@NTFY_SERVER@
readonly NTFY_ENABLED=@NTFY_ENABLED@

CPT_DEB="$HOME_DIR/Sync/CiscoPacketTracer_900_Ubuntu_64bit.deb"
failed_hosts=()

notify_build_failures() {
  local failed_hosts_csv="$1"

  curl --fail --silent --show-error \
    -H "Title: Nix build failures" \
    -H "Priority: high" \
    -H "Tags: warning,computer" \
    -d "daily-nix-build completed with failures for: $failed_hosts_csv" \
    "https://$NTFY_SERVER/harmonia-alerts" > /dev/null || echo "Failed to send ntfy notification" >&2
}

if [ -f "$CPT_DEB" ]; then
  echo "Ensuring Cisco Packet Tracer is in store..."
  nix-store --add-fixed sha256 "$CPT_DEB" > /dev/null
fi

nix flake update --no-warn-dirty --refresh

for host in @HOSTS@; do
  echo "=========================================="
  echo "Building system closure for: $host"
  echo "=========================================="

  if ! nix build ".#nixosConfigurations.$host.config.system.build.toplevel" \
    --no-warn-dirty \
    --out-link "$GC_ROOT/$host"; then
    failed_hosts+=("$host")
  fi
done

if [ "${#failed_hosts[@]}" -gt 0 ]; then
  failed_hosts_csv=$(IFS=', '; echo "${failed_hosts[*]}")

  echo "Build failures detected for: $failed_hosts_csv" >&2
  if [ "$NTFY_ENABLED" = "true" ]; then
    notify_build_failures "$failed_hosts_csv"
  fi
fi
