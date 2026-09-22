{ lib, modulesPath, ... }:
{
  imports = [ "${modulesPath}/virtualisation/amazon-image.nix" ];

  services.amazon-ssm-agent.enable = lib.mkForce false;
}
