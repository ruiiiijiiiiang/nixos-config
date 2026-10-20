{
  imports = [
    ../files
  ];

  home.stateVersion = "26.05";

  custom.home = {
    development.enable = true;
    memory.enable = true;
    dotfiles = {
      enable = true;
      role = "workstation";
      host = "desktop";
    };
  };
}
