{ inputs, ... }:

{
  imports = [
    inputs.agenix.nixosModules.default
  ];

  services = {
    xserver.xkb = {
      layout = "us";
      options = "caps:escape";
    };
  };

  age.identityPaths = [ "/home/rui/.ssh/id_ed25519" ];
}
