{
  imports = [
    ../modules/files
  ];

  custom.home = {
    dotfiles = {
      enable = true;
      role = "workstation";
      host = "arch";
    };
  };
}
