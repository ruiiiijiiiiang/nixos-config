{ pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    linux-firmware
    cachix
    lsof
    wget
    pciutils
    usbutils
    hwinfo
    dig
    traceroute
    fd
    ripgrep
    systemctl-tui
    tailspin
  ];

  programs = {
    fish.enable = true;
    tcpdump.enable = true;
    vim.enable = true;
  };
}
