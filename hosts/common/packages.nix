{ pkgs, ... }:

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
  ];

  programs = {
    vim.enable = true;
  };
}
