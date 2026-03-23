{ inputs, ... }:

{
  imports = [
    inputs.danksearch.homeModules.default
    ../modules/files
  ];

  custom.home = {
    dotfiles = {
      enable = true;
      role = "workstation";
      host = "framework";
    };
    packages = {
      enable = true;
      role = "workstation";
      host = "framework";
    };
  };
}
