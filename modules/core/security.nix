{
  boot = {
    kernel = {
      sysctl = {
        # Filesystem and process hardening
        "fs.protected_hardlinks" = 1;
        "fs.suid_dumpable" = 0;
        "kernel.dmesg_restrict" = 1;
        "kernel.kptr_restrict" = 2;
        "kernel.randomize_va_space" = 2;
        "kernel.yama.ptrace_scope" = 1;

        # Restrict the BPF JIT compiler
        "net.core.bpf_jit_harden" = 2;

        # Reject unsafe or obsolete network behavior
        "net.ipv4.conf.all.accept_redirects" = 0;
        "net.ipv4.conf.all.accept_source_route" = 0;
        "net.ipv4.conf.all.secure_redirects" = 0;
        "net.ipv4.conf.default.accept_redirects" = 0;
        "net.ipv4.conf.default.accept_source_route" = 0;
        "net.ipv4.conf.default.secure_redirects" = 0;
        "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
        "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
        "net.ipv4.tcp_syncookies" = 1;
        "net.ipv6.conf.all.accept_redirects" = 0;
        "net.ipv6.conf.all.accept_source_route" = 0;
        "net.ipv6.conf.default.accept_redirects" = 0;
        "net.ipv6.conf.default.accept_source_route" = 0;
      };
    };
  };

  security = {
    apparmor.enable = true;
    polkit.enable = true;
    pam.services.su.requireWheel = true;
  };
}
