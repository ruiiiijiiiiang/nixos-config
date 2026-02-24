{ inputs, pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    linux-firmware
    cachix
    systemctl-tui
    lazydocker
    tailspin
    glances
    iotop
    lsof
    ripgrep
    fd
    wget
    inputs.witr.packages.${stdenv.system}.default
  ];

  programs = {
    vim.enable = true;
    git.enable = true;
  };
}
