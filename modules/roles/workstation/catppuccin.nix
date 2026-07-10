{
  config,
  inputs,
  lib,
  ...
}:
let
  cfg = config.custom.roles.workstation.catppuccin;
in
{
  imports = [
    inputs.catppuccin.nixosModules.catppuccin
  ];

  options.custom.roles.workstation.catppuccin = with lib; {
    enable = mkEnableOption "Enable Catppuccin theming";
  };

  config = lib.mkIf cfg.enable {
    catppuccin = {
      enable = true;
      autoEnable = true;
      flavor = "frappe";
      accent = "lavender";
    };
  };
}
