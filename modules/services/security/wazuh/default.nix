{
  inputs,
  config,
  lib,
  ...
}:

{
  imports = [
    inputs.wazuh.nixosModules.default
    ./server.nix
    ./agent.nix
  ];

  options.custom.services.security.wazuh.version = lib.mkOption {
    type = lib.types.str;
    default = "4.14.7";
    description = "Wazuh version for server and agent.";
  };

  config.services.wazuh.version = config.custom.services.security.wazuh.version;
}
