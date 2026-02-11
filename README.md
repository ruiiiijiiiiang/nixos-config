# NixOS Configuration

**Welcome to the future of homelabbing.**

This repository isn't just a collection of config files; it is a **fully declarative, reproducible, and fortified infrastructure** definition for my personal homelab. Built on the bedrock of **NixOS** and **Nix Flakes**, this project represents a complete paradigm shift from fragile, imperative sysadmin tasks to a robust, code-driven ecosystem.

Every single aspect of this infrastructure—from the kernel hardening flags and vlan routing rules to the complex web of containerized microservices and their secret management—is defined in code. Version controlled and GitOps-friendly, it emphasizes **stability** through atomic rollbacks, **observability** via a comprehensive monitoring stack, and **security** with hardened kernels and isolated networking.

We're way past infrastructure-as-code. It's time for infrastructure/network/configuration/security/pipeline all-rolled-into-one-as-code.

## Project Structure

**Architected for Evolution. Built for Scale.**

This infrastructure is engineered following a rigorous **Domain-Driven Design** philosophy. The modules are organized into four distinct, composable layers:

1.  **Core (`modules/core`):** The foundational DNA. Universal baselines shared across all systems, defining the essential "NixOS-ness" of the fleet.
2.  **Platform (`modules/platform`):** The hardware abstraction layer. Whether it's a Raspberry Pi ARM chip or a virtualized x86 hypervisor, this layer handles the metal.
3.  **Roles (`modules/roles`):** The personality injection. A host is defined by its mission: a hardened **Headless Server** guarding the network, or a feature-rich **Workstation** designed for development.
4.  **Services (`modules/services`):** The functional payload. Granular, plug-and-play applications categorized by domain:
    - **Networking:** The mesh that connects it all (DNS, Routing, VPNs).
    - **Observability:** The eyes and ears (Monitoring, Logging, Security Agents).
    - **Apps:** The user experience, grouped by function (Office, Tools, Media, Authentication, Web).

The `flake.nix` is the central cortex, orchestrating these modules to synthesize specific host configurations. A **hybrid deployment strategy** is employed to balance raw performance with operational stability:

- **Native Infrastructure:** Core network services like **Nginx**, **Kea DHCP**, and **WireGuard** run close to the metal via native NixOS modules for maximum throughput and reliability.
- **Containerized Applications:** User-facing apps are encapsulated in **OCI containers** (managed by Podman). This ensures strict isolation, precise version pinning, and a clean separation between the "Application Layer" and the "OS Layer."

## Network Architecture

```ascii
               +------------------+       +-----------------+       +---------------------+
               |  The Internet    |       | Cloudflare Edge |       | Remote VPN Clients  |
               +------------------+       +-----------------+       +---------------------+
                        ^                         ^                           ^
                        |                         |                           |
                  (WAN / ens18)           (Cloudflare Tunnel)         (WireGuard Tunnel)
                        |                         |                           |
                        |                         v                           v
+------------------------------------------------------------------------------------------------------+
| [vm-network] (Proxmox VM)                                                                            |
| 4 vCPU, 4GB RAM                                                                                      |
| Role: Router, Firewall (nftables), DHCP (Kea), DNS master (Pi-hole/Unbound), VPN Gateway (WireGuard) |
+-------------------------------------------------|----------------------------------------------------+
                                                  ^
                                                  |
                                         (LAN Trunk / ens19)
                                                  |
             +------------------------------------|-------------------------------------+
             |                                    |                                     |
             v                                    v                                     v
+-------------------------+    +-------------------------------------+    +----------------------------+
| LAN (Native/Untagged)   |    | VLA (Infra)                         |    | VLAN 88 (DMZ)              |
| Network: 192.168.2.0/24 |    | Network: 192.168.20.0/24            |    | Network: 192.168.88.0/24   |
| Desc: Trusted Clients   |    | Desc: Servers & Infrastructure      |    | Desc: Untrusted Workloads  |
+-------------------------+    +-------------------------------------+    +----------------------------+
| +---------------------+ |    | +---------------------------------+ |    | +------------------------+ |
| | [framework]         | |    | | [vm-app] (Proxmox VM)           | |    | | [vm-cyber] (Proxmox VM)| |
| | (Laptop)            | |    | | 10 vCPU, 16GB, GPU Passthrough  | |    | | 4 vCPU, 4GB RAM        | |
| +---------------------+ |    | | Hosts: Jellyfin, Immich, etc.   | |    | | For: Security Research | |
|                         |    | +---------------------------------+ |    | +------------------------+ |
| (Other clients...)      |    | +---------------------------------+ |    |                            |
|                         |    | | [vm-monitor] (Proxmox VM)       | |    |                            |
|                         |    | | 4 vCPU, 6GB RAM                 | |    |                            |
|                         |    | | Hosts: Prometheus, Wazuh, etc.  | |    |                            |
|                         |    | +---------------------------------+ |    |                            |
|                         |    | +---------------------------------+ |    |                            |
|                         |    | | [pi] (Raspberry Pi 4)           | |    |                            |
|                         |    | | Hosts: Home Assistant, DNS slave| |    |                            |
|                         |    | +---------------------------------+ |    |                            |
|                         |    |                                     |    |                            |
|                         |    | DNS VIP: 192.168.20.53 (HA Cluster) |    |                            |
+-------------------------+    +-------------------------------------+    +----------------------------+
             |                                    ^                                     ^
             |                                    |                                     |
             +------------------------------------|-------------------------------------+
```

### The Cybernetic Nexus

The `vm-network` VM serves as the nerve center of the home network. It replaces consumer-grade router firmware with a fully software-defined, hardened networking appliance that routes every packet, enforces strict firewall rules, and inspects traffic for threats.

### Routing Foundation

The network is physically connected via two interfaces, but logically segmented into distinct security zones using VLANs and virtual interfaces:

- **WAN (`ens18`):** The shield against the public internet. Default policy is **DROP**.
- **LAN (`ens19`):** The physical trunk carrying multiple logical networks:
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

Redundancy is the only Reality. The network relies on a high-availability DNS cluster spanning `vm-network`, `pi`, and `pi-legacy` to ensure that ad-blocking and name resolution never sleep.

- **The Stack:** **Pi-hole** for network-wide ad-blocking + **Unbound** for recursive, privacy-respecting DNS-over-TLS resolution.
- **The Redundancy:** **Keepalived** manages a Virtual IP (VIP) that floats across the cluster. If the master node blinks, the VIP instantly migrates to a backup, keeping the network online without a hiccup.

### External Access

To maintain a zero-exposure posture, all external access is brokered by **Cloudflare Tunnels**. This architecture ensures that no ports are open on the WAN interface (besides WireGuard), completely eliminating the need for traditional port forwarding. The `cloudflared` service (running on `vm-network`) establishes an encrypted outbound connection to the Cloudflare edge, securely routing traffic for public-facing subdomains directly to the internal application stack.

Furthermore, all web-facing services are placed behind an **Nginx reverse proxy**, which acts as a unified gateway. SSL/TLS certificates are automatically provisioned and managed by **ACME (Let's Encrypt)**, leveraging Cloudflare for DNS challenges, ensuring robust, always-on encryption without manual intervention.

## The Fleet

The homelab hardware consists of a Raspberry Pi 4 (2GB RAM) and a mini PC acting as a Proxmox host. The mini PC features a 6900hx 16-thread CPU and 32GB DDR5 RAM.

### `framework`

- **The Command Center.** The primary development workstation, tailored for code, creativity, and control.
- **Network:** Home (Native)

### `pi`

- **The Physical Bridge.** Armed with **Z-Wave and Zigbee** radios, it acts as the smart hub running Home Asssistant while standing watch as a backup DNS node.
- **Network:** Infra (VLAN 20)

### `vm-app`

- **The Application Hub.** The workhorse running a suite of self-hosted services, including OpenCloud, Immich, Vaultwarden, and more.
- **Hardware**: 10 vCPU cores, 16GB RAM
- **Extra Power:** Equipped with **GPU Passthrough** from the Proxmox host. This hardware acceleration powers:
  - **Media:** Transcoding for **Jellyfin**.
  - **AI:** Local LLM inference for **Ollama/Open WebUI**.
- **Network:** Infra (VLAN 20)

### `vm-network`

- **The Sentinel.** The primary router, firewall, and DNS authority. It manages the Cloudflare Tunnels, WireGuard VPNs, and Suricata IDS/IPS.
- **Hardware**: 4 vCPU cores, 4GB RAM
- **Network:** Gateway (WAN, Home, Infra, DMZ)

### `vm-monitor`

- **The Watchtower.** Dedicated to keeping the lights on. It hosts the **Beszel Hub**, **Prometheus**, **Grafana**, **Wazuh Server**, and **Gatus** to visualize the health and security of the entire infrastructure.
- **Hardware**: 4 vCPU cores, 6GB RAM
- **Network:** Infra (VLAN 20)

### `vm-cyber`

- **The Armory.** A specialized, security-focused desktop environment loaded with tools for penetration testing, forensics, and reverse engineering.
- **Hardware**: 4 vCPU cores, 4GB RAM
- **Network:** DMZ (VLAN 88)
- **Security:** **None.** This host is intentionally left vulnerable with no defenses to ensure maximum attack efficiency and unrestricted tool usage.

### Shared Services

Every server host (`pi`, `vm-app`, `vm-network`, `vm-monitor`) comes equipped with a standard observability and security sidecar:

- **Beszel & Dockhand Agents:** Real-time system and container metrics.
- **Prometheus Exporters:** Granular telemetry for Nginx, Node, and Podman.
- **Wazuh Agent:** Enterprise-grade security monitoring and intrusion detection.

## Security Configuration

**Ironclad Defense.**

Security isn't a feature; it's the foundation. Every server is hardened against modern threat vectors at the kernel level:

- **Hardened Kernel:** IP Spoofing protection, hidden kernel pointers, and BPF JIT hardening.
- **Memory Defense:** Disabled core dumps, Scudo hardened allocator, and strict PAM limits.
- **Active Defense:** **Fail2Ban** actively bans intruders, while **Wazuh** provides continuous security auditing.

## Secret Management

**Vault-Grade Secrets.**

No more `.env` files leaking in git history. Sensitive data is encrypted at rest using **age** and **agenix**. Secrets are decrypted only at runtime, in-memory, and only by the specific host identity that requires them. It is cryptographically secure and zero-trust by default.

## Build & Deployment

**Deploy Anywhere, Anytime.**

Deployment is atomic, consistent, and flexible.

### Local Binary Cache

**Accelerated Builds. Guaranteed Availability.**

To accelerate deployments and ensure build artifacts are always available even if external services are not, this infrastructure runs its own private binary cache powered by **Harmonia**. Every night, a scheduled job automatically builds the latest configurations for all major hosts and populates the cache. This means that subsequent deployments are lightning-fast, pulling pre-built packages directly from the local network instead of rebuilding them from source or downloading from public caches.

### `nixos-rebuild`

**The Surgical Strike.** For precise, single-host updates initiated directly from the dev machine:

```bash
nixos-rebuild switch --flake .#<hostname> --target-host <hostname>
```

### `colmena`

**The Fleet Commander.** For orchestrating complex, multi-host deployments or targeting specific groups (e.g., all servers) using tags:

```bash
colmena apply -v --on @server
```
