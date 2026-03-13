# NixOS Configuration

**Welcome to the future of homelabbing.**

This repository isn't just a collection of config files; it is a **fully declarative, reproducible, and fortified infrastructure** definition for my personal homelab. Built on the bedrock of **NixOS** and **Nix Flakes**, this project represents a complete paradigm shift from fragile, imperative sysadmin tasks to a robust, code-driven ecosystem.

Every single aspect of this infrastructure — from virtualization resource provisioning and VLAN routing rules to the complex web of containerized microservices and their secret management — is defined in code. Version controlled and GitOps-friendly, it emphasizes **stability** through atomic rollbacks, **observability** via a comprehensive monitoring stack, and **security** with hardened kernels and isolated networking.

My homelab isn't running on expensive, power-hungry enterprise-grade racks. This entire infrastructure is powered by a mini PC, a Raspberry Pi, an unmanaged switch, and a couple of old hard drives. I work with what I have, and my goal is **maximum software correctness**: proving that proper architecture, deliberate design, and disciplined engineering matter far more than raw hardware specs.

The beauty of this setup? **Total vertical alignment.** The hypervisor, the guests, the network topology, the services — every single layer is declared in Nix code. No hybrid imperative management, no XML sprawl, no clicking through web UIs. Just pure, plain-text infrastructure definitions that rebuild atomically and roll back instantly.

We're way past infrastructure-as-code. It's time for infrastructure/networking/configuration/security/pipeline all-rolled-into-one-as-code.

## Project Structure

**Architected for Evolution. Built for Scale.**

This infrastructure is engineered following a rigorous **Domain-Driven Design** philosophy. The modules are organized into four distinct, composable layers:

1. **core (`modules/core`):** The foundational DNA. Universal baselines shared across all systems, defining the essential "NixOS-ness" of the fleet.
2. **platform (`modules/platforms`):** The hardware abstraction layer. Whether it's a Raspberry Pi ARM chip or a virtualized x86 hypervisor, this layer handles the metal. Disk partitioning is fully declarative using **Disko**, defining GPT layouts, LVM volume groups for guest VM disks, and filesystem mounts.
3. **roles (`modules/roles`):** The personality injection. A host is defined by its mission: a hardened **Headless Server** guarding the network, or a feature-rich **Workstation** designed for development.
4. **services (`modules/services`):** The functional payload. Granular, plug-and-play applications categorized by domain:
   - **infra:** The backbone utilities (binary cache, container runtime, backup).
   - **networking:** The mesh that connects it all (DNS, routing, VPN).
   - **observability:** The eyes and ears (monitoring, logging, tracking agents).
   - **security:** The active defense perimeter (Fail2Ban, Wazuh, Suricata, CrowdSec).
   - **apps:** The user experience, grouped by function (office, tools, media, authentication, development).

The `flake.nix` is the central cortex, orchestrating these modules to synthesize specific host configurations. A **hybrid deployment strategy** is employed to balance raw performance with operational stability:

- **Native Infrastructure:** Core network services like **Nginx**, **Kea DHCP**, and **WireGuard** run close to the metal via native NixOS modules for maximum throughput and reliability.
- **Containerized Applications:** User-facing apps are encapsulated in **OCI containers** (managed by Podman). This ensures strict isolation, precise version pinning, and a clean separation between the "Application Layer" and the "OS Layer."

## Network Architecture

```ascii
                  +--------------+        +-----------------+        +--------------------+
                  | The Internet |        | Cloudflare Edge |        | Remote VPN Clients |
                  +--------------+        +-----------------+        +--------------------+
                         ^                         |                           |
                         |                         |                           |
                       (WAN)              (Cloudflare Tunnel)          (WireGuard Tunnel)
                         |                         |                           |
                         |                         v                           v
+------------------------------------------------------------------------------------------------------+
| [vm-network] (libvirt VM)                                                                            |
| 4 vCPU, 2GB RAM, NIC Passthru                                                                        |
| Role: Router, Firewall (nftables), DHCP (Kea), DNS master (Pi-hole/Unbound), VPN Gateway (WireGuard) |
+------------------------------------------------------------------------------------------------------+
                                                   ^
                                                   |
                                              (LAN Trunk)
                                                   |
             +-------------------------------------|-------------------------------------+
             |                                     |                                     |
             v                                     v                                     v
+-------------------------+    +-------------------------------------+    +----------------------------+
| LAN (Native/Untagged)   |    | VLAN 20 (Infra)                     |    | VLAN 88 (DMZ)              |
| Network: 192.168.2.0/24 |    | Network: 192.168.20.0/24            |    | Network: 192.168.88.0/24   |
| Desc: Trusted Clients   |    | Desc: Servers & Infrastructure      |    | Desc: Untrusted Workloads  |
+-------------------------+    +-------------------------------------+    +----------------------------+
| +---------------------+ |    | +---------------------------------+ |    | +------------------------+ |
| | [framework]         | |    | | [vm-app] (libvirt VM)           | |    | | [vm-cyber] (libvirt VM)| |
| | (Laptop)            | |    | | 8 vCPU, 12GB RAM, GPU Passthru  | |    | | 4 vCPU, 4GB RAM        | |
| +---------------------+ |    | | Hosts: Jellyfin, Immich, etc.   | |    | | For: Security Research | |
|                         |    | +---------------------------------+ |    | +------------------------+ |
| (Other clients...)      |    | +---------------------------------+ |    |                            |
|                         |    | | [vm-monitor] (libvirt VM)       | |    |                            |
|                         |    | | 4 vCPU, 4GB RAM                 | |    |                            |
|                         |    | | Hosts: Prometheus, Wazuh, etc.  | |    |                            |
|                         |    | +---------------------------------+ |    |                            |
|                         |    | +---------------------------------+ |    |                            |
|                         |    | | [pi] (Raspberry Pi 4)           | |    |                            |
|                         |    | | Hosts: Home Assistant, DNS slave| |    |                            |
|                         |    | +---------------------------------+ |    |                            |
|                         |    |                                     |    |                            |
|                         |    | DNS VIP: 192.168.20.53 (HA Cluster) |    |                            |
+-------------------------+    +-------------------------------------+    +----------------------------+
             |                                     ^                                     ^
             |                                     |                                     |
             +-------------------------------------|-------------------------------------+
```

### The Cybernetic Nexus

The `vm-network` VM serves as the nerve center of the home network. It replaces consumer-grade router firmware with a fully software-defined, hardened networking appliance that routes every packet, enforces strict firewall rules, and inspects traffic for threats.

### Routing Foundation

The network is physically connected via two interfaces, but logically segmented into distinct security zones using VLANs and virtual interfaces:

- **WAN (`wan0`):** The shield against the public internet.
- **LAN (`lan0`):** The physical trunk carrying multiple logical networks:
  - **Home (Native):** Trusted user devices (e.g., `framework`).
    - _Routing:_ Unrestricted access to WAN, Infra, DMZ, and VPN.
  - **VLAN 20 (`infa0`):** Dedicated management lane for servers and critical infrastructure (e.g., `pi`, `vm-app`, `vm-monitor`).
    - _Routing:_ Access to WAN. Isolated from Home.
  - **VLAN 88 (`dmz0`):** Isolated zone for untrusted workloads (e.g., `vm-cyber`).
    - _Routing:_ Access to WAN. Restricted access to Infra for DNS (UDP/TCP 53) only. No access to Home.
- **WireGuard (`wg0`):** Secure remote access tunnel.
  - _Routing:_ Authenticated peers get full access to Home, Infra, and DMZ networks.

Powered by **NFTables**, the firewall enforces a strict "default drop" policy for forwarding. Traffic is explicitly permitted based on the source zone:

- **Home:** Trusted; can initiate connections to anywhere.
- **Infra/DMZ:** Untrusted; can only egress to the internet (WAN), with DMZ having a pinhole into Infra for DNS.
- **VPN:** Trusted; treated effectively as an extension of the Home network.

### High-Availability DNS

Redundancy is the only reliability. The network relies on a high-availability DNS cluster between `vm-network` and `pi` to ensure that ad-blocking and name resolution never sleep.

- **The Stack:** **Pi-hole** for network-wide ad-blocking + **Unbound** for recursive, privacy-respecting DNS-over-TLS resolution.
- **The Redundancy:** **Keepalived** manages a Virtual IP (VIP) that floats across the cluster. If the master node blinks, the VIP instantly migrates to a backup, keeping the network online without a hiccup.

### External Access

To maintain a zero-exposure posture, all external access is brokered by **Cloudflare Tunnels**. This architecture ensures that no ports are open on the WAN interface (besides WireGuard), completely eliminating the need for traditional port forwarding. The `cloudflared` service (running on `vm-network`) establishes an encrypted outbound connection to the Cloudflare edge, securely routing traffic for public-facing subdomains directly to the internal application stack.

Furthermore, all web-facing services are placed behind an **Nginx reverse proxy**, which acts as a unified gateway. SSL/TLS certificates are automatically provisioned and managed by **ACME (Let's Encrypt)**, leveraging Cloudflare for DNS challenges, ensuring robust, always-on encryption without manual intervention.

## The Fleet

This infrastructure comprises six distinct hosts. Here's the breakdown:

### `framework`

- **The Command Center.** The primary development workstation, tailored for code, creativity, and control.
- **Network:** Home (Native)

### `pi`

- **The Physical Bridge.** Armed with **Z-Wave** and **Zigbee** radios, acting as the smart hub running Home Assistant while standing watch as a backup DNS node.
- **Hardware**: Raspberry Pi 4 with 2GB RAM
- **Network:** Infra (VLAN 20)

### `hypervisor`

- **The Bedrock.** This mini PC runs **NixOS with libvirt** as a headless hypervisor host. It spawns and manages four virtual machines (`vm-network`, `vm-app`, `vm-monitor`, `vm-cyber`), powered by the NixVirt module. The entire virtualization stack — from VLAN-filtered bridges to PCI passthrough to VM lifecycle management — is defined declaratively.
- **Hardware**: AMD 6900HX, 32GB RAM
- **Network:** Infra (VLAN 20)

### `vm-network`

- **The Sentinel.** The primary router, firewall, and DNS authority. It manages the Cloudflare Tunnels, WireGuard VPNs, and Suricata IDS/IPS. A physical NIC is passed through from the hypervisor to serve as the WAN interface, providing direct hardware access for maximum throughput and security.
- **Hardware**: 4 vCPU cores, 2GB RAM, NIC passthrough (WAN)
- **Network:** Gateway (WAN, Home, Infra, DMZ)

### `vm-app`

- **The Powerhouse.** The main application server. GPU passthrough enables hardware-accelerated transcoding for Jellyfin. It runs my complete suite of user-facing services: Immich for photos, Paperless-ngx for documents, Forgejo for code, and more.
- **Hardware**: 8 vCPU cores, 12GB RAM, GPU passthrough
- **Network:** Infra (VLAN 20)

### `vm-monitor`

- **The Watchtower.** Dedicated to keeping the lights on. It hosts the **Beszel Hub**, **Prometheus**, **Loki**, **Wazuh Server**, and **Gatus** to visualize the health and security of the entire infrastructure.
- **Hardware**: 4 vCPU cores, 4GB RAM
- **Network:** Infra (VLAN 20)

### `vm-cyber`

- **The Armory.** A specialized, security-focused desktop environment loaded with tools for penetration testing, forensics, and reverse engineering.
- **Hardware**: 4 vCPU cores, 4GB RAM
- **Network:** DMZ (VLAN 88)
- **Security:** **None.** This host is intentionally left vulnerable with no defenses to ensure maximum attack efficiency and unrestricted tool usage.

### Shared Services

Every server host (`pi`, `vm-network`, `vm-app`, `vm-monitor`) comes equipped with a standard observability and security sidecar:

- **Prometheus Exporters:** Granular telemetry for Nginx, Node, Podman, etc.
- **Promtail:** Grafana Loki agent for collecting `systemd-journal` logs.
- **Beszel Agent:** Custom monitoring agent for real-time insights and control.
- **Dockhand Agent (Hawser):** Lightweight container agent for OCI container monitoring and management.
- **Wazuh Agent:** Enterprise-grade security monitoring and intrusion detection.

## Security Configuration

**Ironclad Defense.**

Security isn't a feature; it's the foundation. Every server is hardened against modern threat vectors at the kernel level:

- **Hardened Kernel:** IP Spoofing protection, hidden kernel pointers, and BPF JIT hardening.
- **Memory Defense:** Disabled core dumps, Scudo hardened allocator, and strict PAM limits.
- **Active Defense:** **Fail2Ban** actively bans intruders, while **Wazuh** provides continuous security auditing.

## Secret Management

**Vault-Grade Secrets.**

No more `.env` files leaking in git history. Sensitive data is encrypted at rest using **agenix**. Secrets are decrypted only at runtime, in-memory, and only by the specific host identity that requires them. It is cryptographically secure and zero-trust by default.

## Operations & Infrastructure

**Atomic. Reproducible. Resilient.**

The operational layer transforms manual sysadmin workflows into deterministic, code-driven automation. Every deployment is atomic, every rollback is instantaneous, and data is continuously protected.

### Binary Cache & Pre-Built Artifacts

A private **Harmonia** binary cache runs on `vm-app`, serving as the fleet's internal package repository. A nightly job pre-builds all host configurations and populates the cache with compiled derivations. Deployments pull pre-built packages directly from the local network instead of rebuilding from source or downloading from public caches. This eliminates compilation overhead and guarantees consistent deployment artifacts across the infrastructure.

### Deployment Workflows

**Dual-Pipeline Architecture.**

The infrastructure employs a dual CI/CD strategy, enabling both local-first and remote fallback deployments:

- **Local Pipeline (Forgejo):** Executes directly on `vm-app` with native Podman socket access. Deploys to all virtual machines over SSH via the Infra VLAN. Rebuilds and activates NixOS configurations atomically. Zero overhead. Maximum performance.
- **Remote Pipeline (GitHub Actions):** Establishes a WireGuard tunnel into the homelab for external access. Deploys to all hosts including `pi` using ARM-native runners. Accessible from anywhere. Environment independence.

The local Forgejo instance doubles as a private **OCI container registry**. CI pipelines build, push, and version container images for personal projects, creating a self-contained artifact ecosystem consumed across the entire infrastructure.

### Automated Backup

**Continuous Data Protection.**

Critical data is protected through a multi-tier backup strategy:

- **Database Backup:** **db-auto-backup** automatically dumps all containerized databases via the Podman socket.
- **Filesystem Backup:** **Restic** performs incremental, encrypted snapshots of critical paths with intelligent retention.

### Hypervisor Architecture

**Vertical Integration. End to End.**

Using the **NixVirt** module, every VM is defined as a Nix derivation — CPU allocation, memory size, disk backend (LVM logical volumes), network interfaces with VLAN tagging, PCI device passthrough, and even lifecycle hooks for GPU reset workarounds. The host bridge is configured via `systemd-networkd` with VLAN filtering, allowing guests to trunk into segregated networks without any imperative configuration.

What makes this truly powerful is the **total alignment**: the hypervisor host, the VM definitions, the guest OS configurations, and the services they run are all declared in the same Nix flake. Change a VM's VLAN assignment? Update one line in Nix, rebuild, and the entire networking stack reconfigures atomically. Need to passthrough a piece of hardware? Declare it in the guest config, and the host automatically binds the right kernel modules and IOMMU groups. Everything is type-checked, reproducible, and instantly auditable in git history.
