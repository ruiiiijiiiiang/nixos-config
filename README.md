# NixOS Configuration

**Welcome to the future of homelabbing.**

This repository isn't just a collection of config files; it is a **fully declarative, reproducible, and fortified infrastructure** definition for my personal homelab. Built on the bedrock of **NixOS** and **Nix Flakes**, this project represents a complete paradigm shift from fragile, imperative sysadmin tasks to a robust, code-driven ecosystem.

Every single aspect of this infrastructure—from the kernel hardening flags and firewall rules to the complex web of containerized microservices and their secret management—is defined in code. It emphasizes **stability** through atomic rollbacks, **observability** via a comprehensive monitoring stack, and **security** with hardened kernels and isolated networking.

Forget "it works on my machine." Here, the entire state of the machine _is_ the code.

## Architecture

This infrastructure is engineered for **modularity and scale**. A shared `common` core ensures consistency across the fleet, while host-specific configurations in `hosts/` define unique personalities. The `flake.nix` acts as the conductor, orchestrating the entire symphony of NixOS systems, home-manager environments, and development shells.

Services aren't just "installed"; they are defined as composable modules. A **hybrid deployment strategy** is employed to balance performance with stability:

- **Native Infrastructure:** Core components like **Nginx**, **Kea DHCP**, and **WireGuard** run natively via NixOS modules. This maximizes performance, minimizes overhead, and leverages deep system integration for unmatched reliability.
- **Containerized Applications:** User-facing applications are encapsulated in **OCI containers** (managed by Podman). This isolates complex dependencies, allows for precise version pinning independent of the host system, and eliminates build failures, ensuring that the "application layer" remains distinct from the "OS layer."

## Hosts

### Shared Services

Running on all server hosts (`pi`, `vm-app`, `vm-network`, `vm-monitor`).

- **Beszel Agent:** System monitoring agent.
- **Dockhand Agent:** Container monitoring agent.
- **Nginx:** A reverse proxy.
- **Prometheus Exporters:** Exporters for Nginx, Node, and Podman.
- **Scanopy Daemon:** Network discovery scanning daemon.
- **Wazuh Agent:** A security monitoring agent.

### `framework`

This is the main development machine, a Framework laptop.

### `pi`

This configuration manages a Raspberry Pi 4 setup for self-hosting various services.

#### Services

- **DNS:** Pi-hole with Unbound for ad-blocking and DNS resolution (backup DNS server).
- **Home Assistant:** A home automation platform.

### Virtual Machines (Proxmox)

The virtualization layer is powered by **Proxmox**, but the VM structures are strictly defined in code using **Disko**. Each VM leverages a high-performance dual-disk strategy:

- **Internal SSD** (`/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi0`): Hosts the root filesystem (`/`) for optimal system performance
- **External Hard Drive** (`/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi1`): Mounted at `/data` and provides storage for `/home` and `/var` via bind mounts

This configuration ensures that system files benefit from SSD speed while user data and service states are stored on the larger external drive with automatic failover support (`nofail` mount option).

### `vm-app`

This virtual machine is dedicated to running various self-hosted applications.

#### Services

- **Atuin:** A tool for syncing, searching, and managing shell history.
- **Dawarich:** A GPS tracking and location history service.
- **Dockhand:** A lightweight container management UI.
- **Homepage:** A dashboard for self-hosted services.
- **Immich:** A photo and video backup solution.
- **KaraKeep:** A bookmark management system.
- **Memos:** A lightweight, self-hosted note-taking service.
- **Microbin:** A small, simple, and secure pastebin service.
- **Opencloud:** A file sharing and editing service.
- **Paperless:** A document management system.
- **PocketID:** An oauth2 authentication service.
- **Reitti:** A self-hosted routing and navigation service with OpenStreetMap integration.
- **Stirling PDF:** A web-based PDF manipulation tool.
- **Syncthing:** A continuous file synchronization program.
- **Vaultwarden:** An unofficial Bitwarden password manager server.
- **Website:** A personal blog website.
- **Yourls:** A URL shortener.

### `vm-network`

**The Digital Gatekeeper.** This VM is the nerve center of the home network, routing every packet, enforcing firewall rules, and inspecting traffic. It replaces consumer router firmware with a fully software-defined, hardened networking appliance.

#### Network Architecture

The host is configured with two network interfaces to function as a software router:

- **WAN (`ens18`):** Connected to the ISP modem. Acquires an IP via DHCP from the ISP.
- **LAN (`ens19`):** Connected to the Deco access points. Serves as the gateway for the internal network.

Core networking features include:

- **NAT & IP Forwarding:** Masquerades internal traffic to the WAN interface.
- **Firewall:** Trusted LAN traffic; restricted WAN ingress.
- **Kea DHCP:** Provides IPv4 address management with static reservations and dynamic pools.

#### Services

- **Cloudflared:** A daemon for Cloudflare Tunnel (centralized ingress).
- **DNS:** Pi-hole with Unbound for DNS filtering and resolution (primary DNS server).
- **DynDNS:** A dynamic DNS service.
- **Kea DHCP:** High-performance DHCPv4 server.
- **Suricata:** A high-performance Network IDS, IPS and Network Security Monitoring engine.
- **WireGuard:** A communication protocol and free and open-source software that implements encrypted virtual private networks.

### `vm-monitor`

This virtual machine is dedicated to monitoring the other hosts and services.

#### Services

- **Beszel Hub:** Central hub for Beszel monitoring.
- **Dockhand Server:** Container management UI.
- **Gatus:** A health check and status monitoring service.
- **Scanopy:** A network discovery service (Server).
- **Prometheus Server:** A monitoring and alerting toolkit.
- **Wazuh Server:** A security monitoring platform.

### `vm-security`

This virtual machine is set up as a security-focused desktop environment, with a variety of tools for penetration testing, forensics, and reverse engineering.

#### Security Tools

- **Recon & Networking:** `nmap`, `masscan`, `netcat`, `socat`, `tcpdump`, `tshark`
- **Web Security:** `burpsuite`, `sqlmap`, `nikto`, `gobuster`, `dirb`, `whatweb`
- **Passwords & Auth:** `john`, `hashcat`
- **Exploitation:** `metasploit`, `exploitdb`
- **Forensics:** `binwalk`, `file`, `xxd`, `jq`, `steghide`, `exiftool`, `binsider`, `zsteg`
- **Utilities:** `unzip`, `unrar`, `ouch`, `lazynmap`

## DNS Architecture

Both `vm-network` and `pi` run Pi-hole with Unbound for network-wide ad-blocking and secure DNS resolution:

- **Pi-hole:** Provides DNS-based ad-blocking using multiple curated blocklists (HaGeZi, Steven Black, AdGuard DNS, etc.)
- **Unbound:** Acts as a recursive DNS resolver with DNS-over-TLS, forwarding queries to Quad9 (9.9.9.9) for enhanced privacy
- **Redundancy:** The home router is configured to use `vm-network` as the primary DNS server and `pi` as backup, ensuring continuous DNS service even if one host goes down

## Security Configuration

**Paranoid by Design.** Security isn't an afterthought; it's baked into the kernel. Every server in this fleet is hardened against modern threat vectors, featuring:

### Kernel Hardening

- **IP Spoofing Prevention:** Reverse path filtering enabled on all interfaces
- **ICMP Redirect Protection:** Disabled to prevent MITM attacks
- **Kernel Log Restriction:** Access to kernel ring buffer (`dmesg`) restricted to root only
- **Kernel Pointer Hiding:** Kernel memory addresses hidden from unprivileged users (KASLR protection)
- **BPF JIT Hardening:** eBPF JIT compiler hardened against spraying attacks

### Memory Protection

- **Core Dumps Disabled:** System-wide core dump generation disabled to prevent sensitive data leakage
- **Scudo Allocator:** Memory allocator hardened with zero-content initialization to prevent information leaks
- **PAM Limits:** Hard limit on core file size set to 0 for all users

### Network Security

- **Fail2Ban:** Automated intrusion prevention system with:
  - 1-hour ban time for initial offenses
  - Maximum 5 retry attempts within 10 minutes
  - Aggressive SSH monitoring mode
  - Recidive jail: Repeat offenders banned for 1 week after 5 violations within 1 day

## Secret Management (agenix)

**Secrets, Kept Secret.** No more `.env` files floating around. Sensitive data is encrypted at rest using `age` and `agenix`, decrypted only at runtime by the specific host identity that needs it. It's GitOps-friendly and cryptographically secure.

- **Encryption:** Secrets are encrypted using `age` and stored as `.age` files in the `secrets/` directory.
- **Decryption:** Each host is configured to decrypt secrets at build time. The `age.identityPaths` option in each host's configuration points to the host's SSH private key, which is used for decryption.
- **Declaration:** The `secrets/secrets.nix` file maps each secret file to the public key(s) that can encrypt it.
- **Usage:** Modules that require secrets reference the decrypted path via `config.age.secrets.<secret-name>.path`.

## Build & Deployment

**Deploy Anywhere, Anytime.** Whether it's a local switch or a remote fleet update, deployment is atomic and consistent.

### `nixos-rebuild`

To build and switch to a new generation for a host, you would run the following command on the target machine:

```bash
nixos-rebuild switch --flake .#<hostname>
```

### `colmena`

`colmena` is used for remote deployment. To deploy to a specific host, you would run:

```bash
colmena apply -v --on <hostname>
```

### GitHub Actions

Deployment to various hosts (pi, vm-app, vm-network) is automated via a GitHub Actions workflow, which can be triggered manually. The workflow performs the following steps:

1.  **Checkout repository:** Clones the repository.
2.  **Set Host IP Address:** Determines the IP address of the target host based on the selected input.
3.  **Install Nix:** Sets up Nix with experimental features.
4.  **Install and Connect WireGuard:** Installs WireGuard and connects to the home network using a VPN configuration stored in GitHub secrets.
5.  **Setup SSH:** Configures SSH with a private key stored in GitHub secrets for authentication with the target host.
6.  **NixOS Rebuild & Switch:** Builds the NixOS configuration for the selected host and deploys it over SSH.
