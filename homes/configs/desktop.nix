{ inputs, ... }:
{
  imports = [
    inputs.agenix.homeManagerModules.default
    ../files
  ];

  home.stateVersion = "26.05";

  custom.home = {
    development.enable = true;
    dotfiles = {
      enable = true;
      role = "workstation";
      host = "desktop";
    };
  };
}
