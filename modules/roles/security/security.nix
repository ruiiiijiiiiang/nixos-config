{
  config,
  lib,
  ...
}:
let
  cfg = config.custom.roles.security.services;
in
{
  options.custom.roles.security.security = with lib; {
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
    };

    security = {
      apparmor.enable = false;
      sudo.wheelNeedsPassword = false;
    };

    users.users.rui.extraGroups = [ "pcap" ];
  };
}
