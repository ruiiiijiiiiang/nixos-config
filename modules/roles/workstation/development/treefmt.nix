{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.roles.workstation.development.treefmt;
in
{
  options.custom.roles.workstation.development.treefmt = {
    enable = lib.mkEnableOption "Enable treefmt workspace formatting integration";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      (inputs.treefmt-nix.lib.evalModule pkgs {
        projectRootFile = "flake.nix";
        programs = {
          nixfmt.enable = true;
          rustfmt.enable = true;
          ruff = {
            enable = true;
            check = true;
            format = true;
          };
          shfmt.enable = true;
        };
      }).config.build.wrapper
    ];
  };
}
