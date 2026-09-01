{ inputs, ... }:
{
  imports = [
    inputs.wazuh.nixosModules.default
    ./server.nix
    ./agent.nix
  ];
}
