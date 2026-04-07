readonly SELF_FLAKE_PATH=@SELF_FLAKE_PATH@
readonly VOLUME_GROUP=@VOLUME_GROUP@
readonly GUEST_LIST_FILE=@GUEST_LIST_FILE@
readonly GUEST_SIZE_FILE=@GUEST_SIZE_FILE@

if [[ $# -ne 1 ]]; then
  echo "Usage: provision-vm <guest>" >&2
  exit 64
fi

guest="$1"
mapfile -t allowed_guests < <(grep -v '^$' "$GUEST_LIST_FILE")

escape_lvm_name() {
  local name="$1"
  printf '%s' "${name//-/--}"
}

guest_allowed=false
for allowed_guest in "${allowed_guests[@]}"; do
  if [[ "$guest" == "$allowed_guest" ]]; then
    guest_allowed=true
    break
  fi
done

if [[ "$guest_allowed" != true ]]; then
  echo "Unknown guest '$guest'. Allowed guests: ${allowed_guests[*]}" >&2
  exit 65
fi

lv_name="$VOLUME_GROUP/$guest"
legacy_device="/dev/$VOLUME_GROUP/$guest"
device="/dev/mapper/$(escape_lvm_name "$VOLUME_GROUP")-$(escape_lvm_name "$guest")"

if ! lvs "$lv_name" >/dev/null 2>&1; then
  size=""
  while IFS=: read -r sized_guest sized_value; do
    if [[ "$guest" == "$sized_guest" ]]; then
      size="$sized_value"
      break
    fi
  done < <(grep -v '^$' "$GUEST_SIZE_FILE")

  if [[ -z "$size" ]]; then
    echo "Could not determine disk size for $guest" >&2
    exit 1
  fi

  echo "Creating missing LV $lv_name ($size)"
  lvcreate -L "$size" -n "$guest" "$VOLUME_GROUP"
fi

udevadm settle

if [[ -e "$legacy_device" && ! -b "$legacy_device" ]]; then
  echo "Refusing to use $legacy_device; it exists but is not a block device" >&2
  exit 1
fi

if [[ ! -b "$device" ]]; then
  echo "Expected block device $device was not created" >&2
  exit 1
fi

if blkid -p "$device" >/dev/null 2>&1; then
  echo "Refusing to overwrite $device; existing disk signature detected" >&2
  exit 0
fi

image_dir="$(
  nix build \
    --no-link \
    --print-out-paths \
    --no-warn-dirty \
    "$SELF_FLAKE_PATH#nixosConfigurations.$guest.config.system.build.diskoImages"
)"
image="$image_dir/primary.raw"

if [[ ! -f "$image" ]]; then
  echo "Expected image $image was not produced" >&2
  exit 1
fi

image_size="$(stat -Lc '%s' "$image")"
device_size="$(blockdev --getsize64 "$device")"

if (( image_size > device_size )); then
  echo "Refusing to seed $device; image is larger than target LV" >&2
  echo "Image size: ${image_size} bytes, LV size: ${device_size} bytes" >&2
  exit 1
fi

echo "Seeding $device from $image"
dd if="$image" of="$device" bs=16M oflag=direct conv=fsync status=progress
