{
  inputs,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    inputs.agenix.nixosModules.default
  ];
  age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  system.autoUpgrade.enable = true;

  security = {
    protectKernelImage = true;
    apparmor = {
      enable = lib.mkDefault true;
      packages = with pkgs; [ apparmor-profiles ];
    };
  };

  services = {
    xserver.xkb = {
      layout = "us";
      options = "caps:escape";
    };

    ntp.enable = false;
    chrony.enable = true;
  };
}
