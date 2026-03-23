{
  home.sessionVariables = {
    ZED_ALLOW_EMULATED_GPU = "1";
  };

  custom.home = {
    dotfiles = {
      enable = true;
      role = "workstation";
    };
    packages = {
      enable = true;
      role = "workstation";
      host = "vm-cyber";
    };
  };
}
