readonly GUEST_LIST_FILE=@GUEST_LIST_FILE@
readonly POLL_INTERVAL_SECONDS=5
readonly WAIT_TIMEOUT_SECONDS=300

shutdown_mode="--poweroff"
pre_delay_spec=""
positional_time_set=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -r|--reboot)
      shutdown_mode="--reboot"
      shift
      ;;
    --help)
      cat <<'EOF'
Usage: shutdown-hypervisor [-r|--reboot] [+N]

Send `virsh shutdown --mode agent` to all guests, wait until they are off,
then power off or reboot the hypervisor.

Options:
  -r, --reboot Reboot the hypervisor instead of powering it off
  +N           Wait N minutes before starting guest shutdown
EOF
      exit 0
      ;;
    *)
      if [[ "$positional_time_set" == true ]]; then
        echo "Unexpected extra argument: $1" >&2
        exit 64
      fi
      pre_delay_spec="$1"
      positional_time_set=true
      shift
      ;;
  esac
done

if [[ -n "$pre_delay_spec" ]]; then
  if [[ "$pre_delay_spec" =~ ^\+[0-9]+$ ]]; then
    delay_minutes=${pre_delay_spec#+}
    echo "Waiting ${delay_minutes} minute(s) before starting guest shutdown"
    sleep $((delay_minutes * 60))
  else
    echo "Expected time in +N format, got '$pre_delay_spec'" >&2
    exit 64
  fi
fi

mapfile -t guests < <(tac "$GUEST_LIST_FILE")

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
    shutdown "$shutdown_mode" "now"
    exit 0
  fi

  echo "Waiting for guests to stop: ${pending_guests[*]}"
  sleep "$POLL_INTERVAL_SECONDS"
done

echo "Timed out waiting for guests to shut down" >&2
exit 1
