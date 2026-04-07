readonly GUEST_LIST_FILE=@GUEST_LIST_FILE@
readonly POLL_INTERVAL_SECONDS=5
readonly WAIT_TIMEOUT_SECONDS=300

shutdown_mode="--poweroff"
shutdown_time="now"
positional_time_set=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -r|--reboot)
      shutdown_mode="--reboot"
      shift
      ;;
    --time)
      if [[ $# -lt 2 ]]; then
        echo "Missing value for --time" >&2
        exit 64
      fi
      shutdown_time="$2"
      shift 2
      ;;
    --help)
      cat <<'EOF'
Usage: shutdown-hypervisor [-r|--reboot] [--time TIME] [TIME]

Send `virsh shutdown --mode agent` to all guests, wait until they are off,
then power off or reboot the hypervisor.

Options:
  -r, --reboot Reboot the hypervisor instead of powering it off
  --time TIME  Time argument passed to shutdown after guests are off
  TIME         Positional shutdown time, like `+5` or `22:30`
EOF
      exit 0
      ;;
    *)
      if [[ "$positional_time_set" == true ]]; then
        echo "Unexpected extra argument: $1" >&2
        exit 64
      fi
      shutdown_time="$1"
      positional_time_set=true
      shift
      ;;
  esac
done

mapfile -t guests < "$GUEST_LIST_FILE"

for guest in "${guests[@]}"; do
  if ! virsh dominfo "$guest" >/dev/null 2>&1; then
    echo "Skipping undefined guest $guest"
    continue
  fi

  state="$(virsh domstate "$guest" | tr -d '\r' | sed 's/^ *//;s/ *$//')"
  if [[ "$state" == "shut off" ]]; then
    echo "Guest $guest is already off"
    continue
  fi

  echo "Requesting guest agent shutdown for $guest"
  virsh shutdown "$guest" --mode agent
done

deadline=$((SECONDS + WAIT_TIMEOUT_SECONDS))

while (( SECONDS < deadline )); do
  pending_guests=()

  for guest in "${guests[@]}"; do
    if ! virsh dominfo "$guest" >/dev/null 2>&1; then
      continue
    fi

    state="$(virsh domstate "$guest" | tr -d '\r' | sed 's/^ *//;s/ *$//')"
    if [[ "$state" != "shut off" ]]; then
      pending_guests+=("$guest:$state")
    fi
  done

  if [[ ${#pending_guests[@]} -eq 0 ]]; then
    echo "All guests are off; invoking host shutdown"
    shutdown "$shutdown_mode" "$shutdown_time"
    exit 0
  fi

  echo "Waiting for guests to stop: ${pending_guests[*]}"
  sleep "$POLL_INTERVAL_SECONDS"
done

echo "Timed out waiting for guests to shut down" >&2
exit 1
