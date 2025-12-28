{ inputs, ... }:

{
  imports = [
    inputs.agenix.nixosModules.default
  ];
  age.identityPaths = [ "/home/rui/.ssh/id_ed25519" ];

  services = {
    xserver.xkb = {
      layout = "us";
      options = "caps:escape";
    };

    ntp.enable = false;
    chrony.enable = true;
  };
}
