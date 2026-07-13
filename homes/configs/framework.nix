{
  imports = [
    ../files
  ];

  home.stateVersion = "25.05";

  custom.home = {
    development.enable = true;
    dotfiles = {
      enable = true;
      role = "workstation";
      host = "framework";
    };
  };
}
