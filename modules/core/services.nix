{
  inputs,
  ...
}:
{
  imports = [
    inputs.agenix.nixosModules.default
  ];
  age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  services = {
    xserver.xkb = {
      layout = "us";
      options = "caps:escape";
    };

    ntp.enable = false;
    chrony.enable = true;
  };
}
