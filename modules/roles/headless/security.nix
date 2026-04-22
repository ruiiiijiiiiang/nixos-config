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
    boot.kernel.sysctl = {
      # Network: Prevent IP Spoofing
      "net.ipv4.conf.all.rp_filter" = "1";
      "net.ipv4.conf.default.rp_filter" = "1";

      # Network: Ignore ICMP Redirects (prevents MITM attacks)
      "net.ipv4.conf.all.accept_redirects" = "0";
      "net.ipv4.conf.default.accept_redirects" = "0";
      "net.ipv4.conf.all.secure_redirects" = "0";
      "net.ipv4.conf.default.secure_redirects" = "0";
      "net.ipv6.conf.all.accept_redirects" = "0";
      "net.ipv6.conf.default.accept_redirects" = "0";

      # Kernel: Restrict access to kernel logs (dmesg)
      "kernel.dmesg_restrict" = "1";

      # Kernel: Hide kernel pointers
      "kernel.kptr_restrict" = "2";

      # Kernel: Restrict BPF (eBPF) JIT compiler
      "net.core.bpf_jit_harden" = "2";
    };

    security = {
      protectKernelImage = true;
      apparmor = {
        enable = true;
        packages = with pkgs; [ apparmor-profiles ];
      };

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
