{ inputs, ... }:

{
  imports = [
    inputs.danksearch.homeModules.default
    ../modules/files
  ];

  custom.home = {
    dotfiles = {
      roles = "workstation";
      host = "framework";
    };
    packages = {
      roles = "workstation";
      host = "framework";
    };
  };
}
