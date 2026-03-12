{ inputs, pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    linux-firmware
    cachix
    systemctl-tui
    tailspin
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
