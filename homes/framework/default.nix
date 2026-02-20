{ inputs, ... }:

{
  imports = [
    ../common
    ./configs.nix
    inputs.danksearch.homeModules.default
  ];

  programs.dsearch.enable = true;
}
