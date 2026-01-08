{ lib, ... }:

{
  imports = [
    ./network.nix
    ./security.nix
    ./services.nix
  ];

  options.custom.server = with lib; {
    network = {
      enable = mkEnableOption "Custom network setup for servers";
    };
    security = {
      enable = mkEnableOption "Custom security setup for servers";
    };
    services = {
      enable = mkEnableOption "Custom services setup for servers";
    };
  };
}
