{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.custom.roles.workstation.development.packages;
in
{
  options.custom.roles.workstation.development.packages = with lib; {
    enable = mkEnableOption "Enable development packages";
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [ inputs.niri.overlays.niri ];

    environment.systemPackages = with pkgs; [
      iw
      nmap
      mtr
      rustscan
      rsync

      # --- Desktop Environment: Niri ---
      networkmanagerapplet
      xwayland-satellite
      catppuccin-cursors.frappeLavender
      wl-clipboard

      # --- Desktop Environment: KDE Plasma ---
      kdePackages.plasma-pa
      kdePackages.qtdeclarative
      kdePackages.kirigami
      catppuccin-kde
    ];

    programs = {
      command-not-found.enable = false;
      kdeconnect.enable = true;
      niri = {
        enable = true;
        package = pkgs.niri-unstable;
      };
      steam.enable = true;
      wireshark.enable = true;
      obs-studio.enable = true;
    };

    fonts = {
      packages = with pkgs; [
        fira
        google-fonts
        liberation_ttf
        nerd-fonts.symbols-only
        noto-fonts
        noto-fonts-color-emoji
        noto-fonts-monochrome-emoji
      ];
      fontconfig = {
        defaultFonts = {
          sansSerif = [ "Noto Sans" ];
          serif = [
            "Liberation Serif"
            "Noto Serif"
          ];
        };
      };
    };
  };
}
