{
  config,
  consts,
  lib,
  ...
}:
let
  inherit (consts) username;
  cfg = config.custom.roles.workstation.cyber.security;
in
{
  options.custom.roles.workstation.cyber.security = with lib; {
    enable = mkEnableOption "Enable relaxed security for cyber role";
  };

  config = lib.mkIf cfg.enable {
    boot = {
      kernelModules = [ "nf_conntrack" ];

      kernel.sysctl = {
        # =====================================================================
        # 1. Local Exploitation & Reverse Engineering
        # Disables kernel protections to aid in debugging and exploit dev
        # =====================================================================
        "kernel.dmesg_restrict" = 0; # Read kernel logs/panics without sudo
        "kernel.kptr_restrict" = 0; # Expose kernel memory addresses for exploit offsets
        "kernel.yama.ptrace_scope" = 0; # Attach debuggers (GDB/Frida) to any user-owned process
        "fs.suid_dumpable" = 2; # Generate core dumps when crashing setuid binaries

        # =====================================================================
        # 2. Advanced Payloads & Container Escapes
        # Enables features heavily used by modern rootkits and namespace exploits
        # =====================================================================
        "kernel.unprivileged_bpf_disabled" = 0; # Write/load eBPF tracing programs as a standard user
        "kernel.unprivileged_userns_clone" = 1; # Create user namespaces (crucial for container escapes)
        "kernel.modules_disabled" = 0; # Allow dynamic loading of custom drivers/rootkits

        # =====================================================================
        # 3. Unprivileged Network Operations
        # Allows standard users to run tools that normally require root
        # =====================================================================
        "net.ipv4.ip_unprivileged_port_start" = 0; # Catch reverse shells or host servers on ports < 1024
        "net.ipv4.ping_group_range" = "0 2147483647"; # Send raw ICMP packets (ping/discovery) without sudo

        # =====================================================================
        # 4. Network Spoofing & Traffic Interception
        # Enables MitM capabilities while defending against hostile network manipulation
        # =====================================================================
        "net.ipv4.ip_forward" = 1; # Route intercepted IPv4 traffic during ARP spoofing
        "net.ipv6.conf.all.forwarding" = 1; # Route intercepted IPv6 traffic during MitM
        "net.ipv4.conf.all.accept_redirects" = 0; # Ignore hostile IPv4 ICMP redirects (Defense)
        "net.ipv6.conf.all.accept_redirects" = 0; # Ignore hostile IPv6 ICMP redirects (Defense)
        "net.ipv4.conf.all.send_redirects" = 0; # Prevent accidental leaking of routing changes

        # =====================================================================
        # 5. High-Speed Scanning & Concurrency Limits
        # Optimizes the TCP stack and state tracking for mass scanning (Nmap/Masscan/Rust tools)
        # =====================================================================
        "net.netfilter.nf_conntrack_max" = 1048576; # Vastly expand state tracking table for heavy scanning
        "net.nf_conntrack_max" = 1048576; # Legacy alias for the above conntrack limit
        "net.ipv4.ip_local_port_range" = "1024 65535"; # Maximize available ephemeral ports for outbound connections
        "net.ipv4.tcp_tw_reuse" = 1; # Aggressively recycle closed sockets in TIME_WAIT state
        "net.core.somaxconn" = 65535; # Maximize queue for incoming connections (C2/payload listeners)
        "net.ipv4.tcp_max_syn_backlog" = 65536; # Maximize queue for half-open inbound connections
      };
    };

    security = {
      apparmor.enable = false;
      sudo.wheelNeedsPassword = false;
      rtkit.enable = true;
      lockKernelModules = false;

      pam.loginLimits = [
        {
          domain = "${username}";
          type = "soft";
          item = "nofile";
          value = "1048576";
        }
        {
          domain = "${username}";
          type = "hard";
          item = "nofile";
          value = "1048576";
        }
        {
          domain = "${username}";
          type = "soft";
          item = "nproc";
          value = "65536";
        }
        {
          domain = "${username}";
          type = "hard";
          item = "nproc";
          value = "65536";
        }
      ];
    };
  };
}
