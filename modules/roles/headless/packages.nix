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
      inputs.file_clipper.packages.${stdenv.hostPlatform.system}.default
      inputs.wezterm.packages.${pkgs.stdenv.hostPlatform.system}.default
      inputs.witr.packages.${stdenv.hostPlatform.system}.default
      lazygit
      lsd
      navi
      neovim
      pay-respects
      starship
      tailspin
    ];

    programs = {
      ssh.startAgent = true;

      bat.enable = true;
      fish.enable = true;
      git.enable = true;
      tcpdump.enable = true;
      yazi.enable = true;
      zoxide.enable = true;
    };
  };
}
