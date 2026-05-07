{ inputs, pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    inputs.file_clipper.packages.${stdenv.hostPlatform.system}.default
    cachix
    dig
    fd
    hwinfo
    linux-firmware
    lsof
    pciutils
    ripgrep
    systemctl-tui
    tailspin
    traceroute
    usbutils
    vim
    witr
    wget
  ];

  programs = {
    git.enable = true;
  };
}
