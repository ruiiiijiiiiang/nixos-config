{
  home.sessionVariables = {
    ZED_ALLOW_EMULATED_GPU = "1";
  };

  custom.home = {
    dotfiles.roles = "workstation";
    packages = {
      roles = "workstation";
      host = "vm-cyber";
    };
  };
}
