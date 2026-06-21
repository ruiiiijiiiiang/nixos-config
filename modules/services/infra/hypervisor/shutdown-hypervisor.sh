readonly POLL_INTERVAL_SECONDS=5
readonly GUEST_TIMEOUT_SECONDS=90

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

Send shutdown requests to guests in a strict order:
vm-public, vm-monitor, vm-app, vm-network.
Non-core guests are shut down first concurrently.

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

readonly CORE_ORDER=("vm-public" "vm-monitor" "vm-app" "vm-network")

# Helper function to gracefully shut down a single guest and wait for it to stop
shutdown_guest_and_wait() {
  local guest="$1"
  local timeout="$2"

  if ! virsh dominfo "$guest" >/dev/null 2>&1; then
    echo "Core guest $guest does not exist, skipping."
    return 0
  fi

  local state
  state="$(virsh domstate "$guest" 2>/dev/null | tr -d '\r' | sed 's/^ *//;s/ *$//' || true)"
  if [[ "$state" == "shut off" ]]; then
    echo "Guest $guest is already off."
    return 0
  fi

  echo "Requesting guest agent shutdown for $guest"
  # Try agent shutdown, fallback to ACPI shutdown if it fails immediately
  if ! virsh shutdown "$guest" --mode agent; then
    echo "Agent shutdown request failed for $guest, sending ACPI shutdown request..."
    virsh shutdown "$guest"
  fi

  local deadline=$((SECONDS + timeout))
  local agent_fallback_tried=false

  while (( SECONDS < deadline )); do
    state="$(virsh domstate "$guest" 2>/dev/null | tr -d '\r' | sed 's/^ *//;s/ *$//' || true)"
    if [[ "$state" == "shut off" ]]; then
      echo "Guest $guest is off."
      return 0
    fi

    # Fallback to ACPI shutdown if agent shutdown is not stopping the VM after 30 seconds
    if [[ "$agent_fallback_tried" == false ]] && (( SECONDS > deadline - timeout + 30 )); then
      echo "Guest $guest still running after 30 seconds; sending ACPI shutdown request..."
      virsh shutdown "$guest"
      agent_fallback_tried=true
    fi

    sleep "$POLL_INTERVAL_SECONDS"
  done

  echo "Timeout reached for guest $guest. Force-destroying..."
  virsh destroy "$guest"
}

# 1. Get all running guests
mapfile -t running_guests < <(virsh list --name | grep -v '^$' || true)

# 2. Separate into non-core and core lists
non_core_guests=()
for guest in "${running_guests[@]}"; do
  is_core=false
  for core in "${CORE_ORDER[@]}"; do
    if [[ "$guest" == "$core" ]]; then
      is_core=true
      break
    fi
  done
  if [[ "$is_core" == false ]]; then
    non_core_guests+=("$guest")
  fi
done

# 3. Shut down non-core guests concurrently first
if [[ ${#non_core_guests[@]} -gt 0 ]]; then
  echo "Shutting down non-core guests concurrently: ${non_core_guests[*]}"
  for guest in "${non_core_guests[@]}"; do
    if virsh shutdown "$guest" --mode agent; then
      echo "Requested guest agent shutdown for non-core $guest"
    else
      echo "Agent shutdown request failed for $guest, sending ACPI shutdown request..."
      virsh shutdown "$guest"
    fi
  done

  # Wait for non-core guests to turn off
  deadline=$((SECONDS + 90))
  while (( SECONDS < deadline )); do
    pending=()
    for guest in "${non_core_guests[@]}"; do
      state="$(virsh domstate "$guest" 2>/dev/null | tr -d '\r' | sed 's/^ *//;s/ *$//' || true)"
      if [[ "$state" != "shut off" ]] && [[ -n "$state" ]]; then
        pending+=("$guest")
      fi
    done
    if [[ ${#pending[@]} -eq 0 ]]; then
      break
    fi
    echo "Waiting for non-core guests: ${pending[*]}"
    sleep "$POLL_INTERVAL_SECONDS"
  done

  # Force destroy any remaining non-core guests
  for guest in "${non_core_guests[@]}"; do
    state="$(virsh domstate "$guest" 2>/dev/null | tr -d '\r' | sed 's/^ *//;s/ *$//' || true)"
    if [[ "$state" != "shut off" ]] && [[ -n "$state" ]]; then
      echo "Timeout reached for non-core guest $guest. Force-destroying..."
      virsh destroy "$guest"
    fi
  done
fi

# 4. Shut down core guests sequentially in the exact specified order
for guest in "${CORE_ORDER[@]}"; do
  # Check if guest is currently running
  state="$(virsh domstate "$guest" 2>/dev/null | tr -d '\r' | sed 's/^ *//;s/ *$//' || true)"
  if [[ "$state" != "shut off" ]] && [[ -n "$state" ]]; then
    echo "Shutting down core guest sequentially: $guest"
    shutdown_guest_and_wait "$guest" "$GUEST_TIMEOUT_SECONDS"
  else
    echo "Core guest $guest is already off or does not exist."
  fi
done

# 5. Invoke host shutdown
echo "All guests are off; invoking host shutdown"
shutdown "$shutdown_mode" "now"
