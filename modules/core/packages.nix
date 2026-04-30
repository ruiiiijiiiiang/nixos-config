{ pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
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
    wget
  ];
}
