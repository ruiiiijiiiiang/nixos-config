{ inputs, pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    linux-firmware
    cachix
    systemctl-tui
    glances
    iotop
    lsof
    ripgrep
    fd
    inputs.witr.packages.${stdenv.system}.default
  ];

  programs = {
    vim.enable = true;
  };
}
