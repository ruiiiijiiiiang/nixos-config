{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.roles.headless.packages;
in
{
  options.custom.roles.headless.packages = with lib; {
    enable = mkEnableOption "Enable headless packages";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      atuin
      btop
      carapace
      comma
      delta
      fastfetch
      fzf
      helix
      inputs.agenix.packages.${stdenv.hostPlatform.system}.default
      lazygit
      lsd
      navi
      starship
      wezterm
    ];

    programs = {
      bat.enable = true;
      fish.enable = true;
      neovim.enable = true;
      pay-respects.enable = true;
      tcpdump.enable = true;
      yazi.enable = true;
      zoxide.enable = true;
    };
  };
}
