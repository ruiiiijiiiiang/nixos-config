# GEMINI.md

## Project Overview

This repository contains a comprehensive NixOS configuration managed using Nix Flakes. It defines the configurations for multiple hosts, ranging from physical hardware like a Framework laptop and Raspberry Pi to specialized virtual machines. The project emphasizes a declarative, reproducible, and secure setup, leveraging various tools and custom modules to manage services, secrets, and deployments.

The project is structured to share common configurations across hosts while allowing for specific overrides and additions. It integrates Home Manager for user-level configuration and uses `agenix` for secure secret management.

## Project Structure

The repository is organized into several key directories:

- `homes/`: Contains Home Manager configurations for users (e.g., `rui`, `vm-cyber`).
- `hosts/`: Defines host-specific NixOS configurations.
  - `framework/`: Configuration for a Framework laptop (GUI, physical).
  - `pi/`: Configuration for a Raspberry Pi (Server, physical).
  - `vm-app/`: Dedicated to application hosting (GPU Passthrough enabled).
  - `vm-network/`: Acts as the central software router (DHCP, DNS, VPN, IPS).
  - `vm-monitor/`: dedicated to system and security monitoring.
  - `vm-cyber/`: Specialized security and forensics environment.
- `modules/`: Custom NixOS modules organized by layer.
  - `core/`: Universal baselines shared across all systems (Hardware, Network, NixOS, Packages).
  - `platform/`: Hardware abstraction layer (Framework, Pi, VM).
  - `roles/`: Host personality definitions (Headless, Security, Workstation).
  - `services/`: Functional payloads categorized by domain (Apps, Networking, Observability).
- `lib/`: Utility functions and constants used throughout the configuration.
- `secrets/`: Encrypted secrets managed by `agenix`.
- `shells/`: Custom development shells (e.g., `rust`, `devops`, `forensics`).

## Building and Running

### Host Deployment

Configurations are applied to target systems using `nixos-rebuild` or `colmena`.

**Local Deployment:**

```bash
nixos-rebuild switch --flake .#<hostname>
```

**Remote Deployment (using Colmena):**

```bash
colmena apply --on <hostname>
```

### Home Manager

User configurations can be applied separately if needed:

```bash
home-manager switch --flake .#<username>
```

### Development Shells

Enter a specialized development environment:

```bash
nix develop .#<shell-name> # e.g., nix develop .#rust
```

## Key Technologies & Conventions

- **Nix Flakes:** Ensures reproducible builds and manages external dependencies.
- **Secret Management:** `agenix` (encrypted with `age`) is used to manage sensitive data securely within the git repository.
- **Containerization:** Services are primarily managed via Podman using the `virtualisation.oci-containers` NixOS option.
- **Networking:**
  - `vm-network` serves as the primary router and gateway.
  - Secure access is facilitated through Cloudflare Tunnels (centralized on `vm-network`) and Nginx reverse proxies.
- **Theming:** The project uses Catppuccin for consistent styling across various applications and environments.
- **CI/CD:** Automated deployment to the Raspberry Pi and VMs is handled via GitHub Actions.

## Network Configuration

This document provides a comprehensive overview of the home network configuration, designed to be used as a knowledge base for an LLM assistant.

### 1. Network Architecture Overview

The network is managed by a central NixOS virtual machine named `vm-network`, which acts as a software-defined router, firewall, and primary network services provider. The architecture follows a declarative model using NixOS, with all configurations defined as code.

The network is physically connected via two main interfaces on `vm-network` but is logically segmented into several distinct security zones using VLANs and virtual interfaces.

-   **Central Router:** `vm-network`
-   **Configuration Management:** NixOS Flakes
-   **Core Technologies:** `nftables` (Firewall), `Kea` (DHCP), `Pi-hole` & `Unbound` (DNS), `WireGuard` (VPN), `Cloudflare Tunnels` (External Access).

### 2. Network Segments (VLANs & Subnets)

The network is segmented into the following logical zones:

| Network Name | Purpose | Subnet / CIDR | Gateway (on `vm-network`) | VLAN ID | Key Hosts & IPs |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Home** | Trusted user devices | `192.168.2.0/24` | `192.168.2.1` | Native (untagged) | `framework`: `192.168.2.10`<br>`arch`: `192.168.2.11` |
| **Infra** | Servers & infrastructure | `192.168.20.0/24` | `192.168.20.1` | `20` | `vm-app`: `192.168.20.2`<br>`vm-monitor`: `192.168.20.3`<br>`pi`: `192.168.20.51` |
| **DMZ** | Untrusted workloads | `192.168.88.0/24` | `192.168.88.1` | `88` | `vm-security`: `192.168.88.10` |
| **VPN** | Remote access peers | `10.5.5.0/24` | `10.5.5.1` | N/A (Virtual) | `framework`: `10.5.5.2`<br>`iphone-16`: `10.5.5.3`<br>... |
| **Podman** | Container networking | `10.88.0.0/16` | N/A | N/A (Internal) | Internal to hosts running containers. |

_Source: `lib/consts.nix`, `modules/services/networking/router/default.nix`_

### 3. Core Network Services (on `vm-network`)

#### 3.1. Routing & Firewall (`nftables`)

`vm-network` handles all inter-VLAN routing and firewalling.

-   **WAN Interface:** `ens18` (Shield against the public internet)
-   **LAN Interface:** `ens19` (Physical trunk carrying VLANs)
-   **VLAN Interfaces:** `infra0` (VLAN 20), `dmz0` (VLAN 88)
-   **Default Policy:** `DROP` for all forwarded traffic. All allowed traffic must be explicitly defined.

**Forwarding Rules Summary:**

-   **From `Home` (`lanInterface`):** Unrestricted access to `WAN`, `Infra`, `DMZ`, and `VPN`.
-   **From `Infra` (`infra0`):**
    -   Can access `WAN` (Internet).
    -   Can access the `Podman` network.
    -   Can access the `DMZ`.
    -   Isolated from the `Home` network.
-   **From `DMZ` (`dmz0`):**
    -   Can access `WAN` (Internet).
    -   Restricted access to `Infra` for DNS (`udp/tcp 53` to `192.168.20.53`) and specific HTTP/S services on `vm-app`.
    -   No access to the `Home` network.
-   **From `VPN` (`wg0`):** Authenticated peers are treated like the `Home` network, with full access to `Home`, `Infra`, and `DMZ`.

_Source: `README.md`, `modules/services/networking/router/default.nix`, `modules/services/networking/wireguard/server.nix`_

#### 3.2. DHCP Server (`Kea`)

`vm-network` runs a Kea DHCP server providing IP addresses to all VLANs.

-   **Home Subnet (`192.168.2.0/24`):**
    -   Range: `192.168.2.50` - `192.168.2.250`
    -   Router/Gateway: `192.168.2.1`
    -   DNS Server: `192.168.20.53` (VIP)
-   **Infra Subnet (`192.168.20.0/24`):**
    -   Range: `192.168.20.100` - `192.168.20.250`
    -   Router/Gateway: `192.168.20.1`
    -   DNS Server: `192.168.20.53` (VIP)
-   **DMZ Subnet (`192.168.88.0/24`):**
    -   Range: `192.168.88.50` - `192.168.88.250`
    -   Router/Gateway: `192.168.88.1`
    -   DNS Server: `192.168.20.53` (VIP)

Static IP reservations are defined for known devices based on their MAC addresses.

_Source: `modules/services/networking/router/default.nix`, `lib/consts.nix`_

#### 3.3. DNS Services (Pi-hole & Unbound)

The network uses a high-availability DNS cluster for filtering and resolution.

-   **Primary DNS IP (VIP):** `192.168.20.53`
-   **DNS Stack:**
    1.  **Pi-hole:** Provides network-wide ad and malware blocking.
    2.  **Unbound:** Acts as a recursive resolver, forwarding queries over DNS-over-TLS to Quad9 (`9.9.9.9`).
-   **High Availability:** `keepalived` manages the Virtual IP (`192.168.20.53`) across a cluster of nodes (`vm-network`, `pi`, `pi-legacy`). If the master node fails a health check (by failing to resolve common domains), the VIP automatically fails over to a backup node.
-   **Local Domains:** The `.ruijiang.me` domain is treated as a private domain for local resolution.

_Source: `modules/services/networking/dns/default.nix`, `lib/consts.nix`_

### 4. Remote Access (WireGuard VPN)

Secure remote access is provided by a WireGuard server running on `vm-network`.

-   **VPN Server:** `vm-network`
-   **Listening Port:** `51820` (UDP)
-   **VPN Interface:** `wg0`
-   **VPN Server IP:** `10.5.5.1`
-   **VPN Subnet:** `10.5.5.0/24`
-   **Peer IPs:** Assigned individually, e.g., `framework` is `10.5.5.2`, `github-action` is `10.5.5.5`.
-   **Access:** As noted in the firewall rules, authenticated VPN peers have full access to the `Home`, `Infra`, and `DMZ` networks.

_Source: `modules/services/networking/wireguard/server.nix`, `lib/consts.nix`_

### 5. External Access & Services

-   **Ingress Method:** `cloudflared` service on `vm-network` establishes secure outbound tunnels to the Cloudflare edge.
-   **WAN Exposure:** No ports are open on the `WAN` interface except for the WireGuard VPN port (`51820/udp`). Traditional port forwarding is not used.
-   **Reverse Proxy:** `Nginx` acts as a reverse proxy to route public-facing subdomains to the correct internal services.
-   **Primary Domain:** `ruijiang.me`
-   **Example Subdomains:**
    -   `ha.ruijiang.me` -> Home Assistant on `pi`
    -   `git.ruijiang.me` -> Forgejo on `vm-app`
    -   `jellyfin.ruijiang.me` -> Jellyfin on `vm-app`
    -   `grafana.ruijiang.me` -> Grafana on `vm-monitor`
    -   `vpn.ruijiang.me` -> Points to the VPN endpoint.

_Source: `README.md`, `lib/consts.nix`_

### 6. Key Mappings & Constants

#### Hostname to MAC Address Mappings

| Hostname | MAC Address |
| :--- | :--- |
| `arch` | `28:0c:50:9c:03:2e` |
| `framework` | `ac:f2:3c:63:d9:f3` |
| `proxmox` | `c8:a3:62:bf:0b:b3` |
| `vm-network` | `bc:24:11:b0:9b:27` |
| `vm-app` | `bc:24:11:71:f8:9b` |
| `vm-monitor`| `bc:24:11:93:b1:94` |
| `vm-security`| `bc:24:11:4b:5f:d4` |
| `pi` | `2c:cf:67:0e:c9:6b` |
| `pi-legacy` | `b8:27:eb:af:a2:33` |

#### Common Ports

| Service | Port |
| :--- | :--- |
| DNS | `53` |
| DHCP | `67` |
| HTTP | `80` |
| HTTPS | `443` |
| SSH | `22` |
| WireGuard | `51820` |
| Pi-hole (Web) | `8008` (internally) |
| Unbound | `5335` (internally) |

_Source: `lib/consts.nix`_

## Self-Hosted Services

The `modules/services/apps/` directory contains configurations for numerous services, organized by domain:

- **Media:** Immich, Jellyfin (GPU accelerated)
- **Office:** Opencloud, Paperless-ngx, Stirling-PDF, Memos, Nextcloud
- **Tools:** Atuin, MicroBin, Syncthing, Home Assistant, Forgejo, LLM (Ollama + Open WebUI - GPU accelerated), SearXNG
- **Security:** Vaultwarden, PocketID
- **Web:** Homepage, Website
