# NixOS Configuration

**Welcome to the future of homelabbing.**

This repository isn't just a collection of config files; it is a **fully declarative, reproducible, and fortified infrastructure** definition for my personal homelab. Built on the bedrock of **NixOS** and **Nix Flakes**, this project represents a complete paradigm shift from fragile, imperative sysadmin tasks to a robust, code-driven ecosystem.

Every single aspect of this infrastructure—from the kernel hardening flags and firewall rules to the complex web of containerized microservices and their secret management—is defined in code. It emphasizes **stability** through atomic rollbacks, **observability** via a comprehensive monitoring stack, and **security** with hardened kernels and isolated networking.

Forget "it works on my machine." Here, the entire state of the machine _is_ the code.

## Project Structure

**Modular by Design. Scalable by Default.**

This infrastructure is engineered following a rigorous **Domain-Driven Design** philosophy. The codebase is organized into four distinct, composable layers:

1.  **Core (`modules/core`):** The foundational DNA. Universal baselines shared across all systems, defining the essential "NixOS-ness" of the fleet.
2.  **Platform (`modules/platform`):** The hardware abstraction layer. Whether it's a Raspberry Pi ARM chip or a virtualized x86 hypervisor, this layer handles the metal.
3.  **Roles (`modules/roles`):** The personality injection. A host is defined by its mission: a hardened **Headless Server** guarding the network, or a feature-rich **Workstation** designed for development.
4.  **Services (`modules/services`):** The functional payload. Granular, plug-and-play applications categorized by domain:
    - **Networking:** The mesh that connects it all (DNS, Routing, VPNs).
    - **Observability:** The eyes and ears (Monitoring, Logging, Security Agents).
    - **Apps:** The user experience, grouped by function (Office, Tools, Media, Security, Web).

The `flake.nix` acts as the grand conductor, orchestrating these modules to synthesize specific host configurations. A **hybrid deployment strategy** is employed to balance raw performance with operational stability:

- **Native Infrastructure:** Core network services like **Nginx**, **Kea DHCP**, and **WireGuard** run close to the metal via native NixOS modules for maximum throughput and reliability.
- **Containerized Applications:** User-facing apps are encapsulated in **OCI containers** (managed by Podman). This ensures strict isolation, precise version pinning, and a clean separation between the "Application Layer" and the "OS Layer."

## Network Architecture

**The Digital Gatekeeper.**

The `vm-network` VM serves as the nerve center of the home network. It replaces consumer-grade router firmware with a fully software-defined, hardened networking appliance that routes every packet, enforces strict firewall rules, and inspects traffic for threats.

### The Routing Core

Two network interfaces define the boundary between the wild internet and the safe intranet:

- **WAN (`ens18`):** The shield against the public internet.
- **LAN (`ens19`):** The gateway to the internal network.

Powered by **NAT & IP Forwarding**, a strict **Firewall**, and **Kea DHCP**, this core ensures seamless connectivity without compromising security.

### High-Availability DNS

Resolution is redundancy. The network relies on a high-availability DNS cluster spanning `vm-network`, `pi`, and `pi-legacy` to ensure that ad-blocking and name resolution never sleep.

- **The Stack:** **Pi-hole** for network-wide ad-blocking + **Unbound** for recursive, privacy-respecting DNS-over-TLS resolution.
- **The Redundancy:** **Keepalived** manages a Virtual IP (VIP) that floats across the cluster. If the master node blinks, the VIP instantly migrates to a backup, keeping the network online without a hiccup.

## The Fleet

### Shared Services

Every server host (`pi`, `vm-app`, `vm-network`, `vm-monitor`) comes equipped with a standard observability and security sidecar:

- **Beszel & Dockhand Agents:** Real-time system and container metrics.
- **Prometheus Exporters:** Granular telemetry for Nginx, Node, and Podman.
- **Wazuh Agent:** Enterprise-grade security monitoring and intrusion detection.

### `framework`

**The Command Center.** The primary development workstation, tailored for code, creativity, and control.

### `pi`

**The Physical Bridge.** A Raspberry Pi 4 that bridges the digital and physical worlds. Armed with **Z-Wave and Zigbee** radios, it acts as the central brain for Home Asssistant while standing watch as a backup DNS node.

### Virtual Machines (Proxmox)

**Virtualized Power.** Powered by **Proxmox** but defined by **Disko**, each VM utilizes a high-performance dual-disk strategy:

- **System Drive (NVMe):** Blazing fast root filesystem (`/`) for instant boot and responsive services.
- **Data Drive (HDD):** Massive storage mounted at `/data` for `/home` and `/var`, ensuring user data survives even total system rebuilds.

#### `vm-app`

**The Application Hub.** The workhorse running the self-hosted suite:

- **Productivity:** Paperless-ngx, Memos, OpenCloud, Stirling PDF.
- **Media & Sync:** Immich, Syncthing.
- **Tools:** Atuin, Dockhand, PocketID, Vaultwarden, and more.

#### `vm-network`

**The Sentinel.** The primary router, firewall, and DNS authority. It manages the Cloudflare Tunnels, WireGuard VPNs, and Suricata IDS/IPS.

#### `vm-monitor`

**The Watchtower.** Dedicated to keeping the lights on. It hosts the **Beszel Hub**, **Prometheus**, **Wazuh Server**, and **Gatus** to visualize the health and security of the entire infrastructure.

#### `vm-security`

**The Armory.** A specialized, security-focused desktop environment loaded with tools for penetration testing, forensics, and reverse engineering.

## Security Configuration

**Paranoid by Design.**

Security isn't a feature; it's the foundation. Every server is hardened against modern threat vectors at the kernel level:

- **Hardened Kernel:** IP Spoofing protection, hidden kernel pointers, and BPF JIT hardening.
- **Memory Defense:** Disabled core dumps, Scudo hardened allocator, and strict PAM limits.
- **Active Defense:** **Fail2Ban** actively bans intruders, while **Wazuh** provides continuous security auditing.

## Secret Management

**Secrets, Kept Secret.**

No more `.env` files leaking in git history. Sensitive data is encrypted at rest using **age** and **agenix**. Secrets are decrypted only at runtime, in-memory, and only by the specific host identity that requires them. It is GitOps-friendly, cryptographically secure, and zero-trust by default.

## Build & Deployment

**Deploy Anywhere, Anytime.**

Deployment is atomic, consistent, and flexible.

### `nixos-rebuild`

**The Surgical Strike.** For precise, single-host updates initiated directly from the dev machine:

```bash
nixos-rebuild switch --flake .#<hostname> --target-host <hostname> --use-remote-sudo
```

### `colmena`

**The Fleet Commander.** For orchestrating complex, multi-host deployments or targeting specific groups (e.g., all servers) using tags:

```bash
colmena apply -v --on @server
```

### GitHub Actions

**The Automated Pipeline.** A CI/CD workflow that can rebuild and deploy the fleet automatically, ensuring the infrastructure is always in sync with the repository.
