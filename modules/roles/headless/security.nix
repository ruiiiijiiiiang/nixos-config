{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.custom.roles.headless.security;
in
{
  options.custom.roles.headless.security = with lib; {
    enable = mkEnableOption "Enable headless security hardening";
  };

  config = lib.mkIf cfg.enable {
    boot = {
      kernel = {
        sysctl = {
          # Network: Prevent IP Spoofing
          "net.ipv4.conf.all.rp_filter" = 1;
          "net.ipv4.conf.default.rp_filter" = 1;
        };
      };
    };

    security = {
      protectKernelImage = true;
      apparmor.packages = [ pkgs.apparmor-profiles ];

      pam.loginLimits = [
        {
          domain = "*";
          item = "core";
          type = "hard";
          value = "0";
        }
      ];
    };

    systemd.coredump.enable = false;

    environment.memoryAllocator.provider = "scudo";
    environment.variables.SCUDO_OPTIONS = "zero_contents=1";
  };
}
