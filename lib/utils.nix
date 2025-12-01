{ lib, pkgs, ... }:

{
  findBinaryFunctionString = ''
    # find_binary_path: Function to locate an executable at runtime across distros.
    # Usage: path=$(find_binary_path "executable_name") || exit 1
    # Returns the absolute path to stdout, or prints error to stderr and returns 1.
    find_binary_path() {
      local name="$1"
      local paths=(
        "/run/current-system/sw/bin/''${name}" # NixOS system profile
        "$HOME/.nix-profile/bin/''${name}"     # Home Manager user profile
        "/usr/bin/''${name}"                   # FHS standard
        "/usr/local/bin/''${name}"             # FHS local
      )

      local found_path=""
      for p in "''${paths[@]}"; do
        if [ -n "$p" ] && [ -x "$p" ]; then # Check if path is non-empty and executable
          found_path="$p"
          break
        fi
      done

      if [ -z "$found_path" ]; then
        echo "Error: Executable "''${name}" not found in any of the expected locations at runtime." >&2
        echo "Checked paths:" >&2
        for p in "''${paths[@]}"; do
          if [ -n "$p" ]; then
            echo "  - '$p'" >&2
          fi
        done
        return 1 # Indicate failure
      else
        echo "$found_path"
        return 0 # Indicate success
      fi
    }
  '';
}
