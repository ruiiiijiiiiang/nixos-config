{
  config,
  lib,
  ...
}:
let
  cfg = config.custom.roles.cyber.services;
in
{
  options.custom.roles.cyber.security = with lib; {
    enable = mkEnableOption "Relax security configs for attack box";
  };

  config = lib.mkIf cfg.enable {
    boot.kernel.sysctl = {
      "kernel.dmesg_restrict" = 0;
      "kernel.kptr_restrict" = 0;
      "kernel.yama.ptrace_scope" = 0;

      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;

      "fs.suid_dumpable" = 1;

      "net.ipv4.ip_unprivileged_port_start" = 0;
    };

    security = {
      apparmor.enable = false;
      sudo.wheelNeedsPassword = false;
      rtkit.enable = true;
    };
  };
}
