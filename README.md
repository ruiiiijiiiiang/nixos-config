# NixOS Configuration

This repository contains the NixOS configurations for several hosts, managed using Nix Flakes.

## Architecture

The configurations are organized by host, with a `common` configuration that is shared across all hosts. Each host has its own directory in the `hosts/` directory, which contains the specific configuration for that host. The `flake.nix` file ties everything together, defining the NixOS configurations for each host, as well as `home-manager` configurations and development shells.

Services are managed through a combination of NixOS options and custom modules. Many services are containerized using Podman, and Nginx is used as a reverse proxy to provide access to them. Secrets are managed using `agenix`, and deployments are handled by `colmena` and GitHub Actions.

## Hosts

### `framework`

This is the main development machine, a Framework laptop.

### `pi`

This configuration manages a Raspberry Pi 4 setup for self-hosting various services. It's designed to be secure, efficient, and easily reproducible.

### `vm-app`

This virtual machine is dedicated to running various self-hosted applications.

#### Services

- **Atuin:** A tool for syncing, searching, and managing shell history.
- **BentoPDF:** A PDF service.
- **Beszel:** A messaging service (agent).
- **Cloudflared:** A daemon for Cloudflare Tunnel.
- **Dawarich:** A GPS service.
- **Homepage:** A dashboard for self-hosted services.
- **Immich:** A photo and video backup solution.
- **Microbin:** A small, simple, and secure pastebin service.
- **Monit:** A utility for managing and monitoring Unix systems.
- **Nextcloud:** A file-hosting service.
- **Nginx:** A reverse proxy.
- **Paperless:** A document management system.
- **PocketID:** An authentication service.
- **Portainer:** A container management UI.
- **Prometheus Exporters:** Exporters for Nginx, Node, and Podman.
- **Syncthing:** A continuous file synchronization program.
- **Vaultwarden:** An unofficial Bitwarden password manager server.
- **Wazuh Agent:** A security monitoring agent.
- **Website:** A personal website.
- **Yourls:** A URL shortener.

### `vm-network`

This virtual machine is responsible for network-level services.

#### Services

- **Beszel Agent:** A messaging service (agent).
- **DNS:** Unbound and Pi-hole for DNS filtering and resolution.
- **DynDNS:** A dynamic DNS service.
- **Monit:** A utility for managing and monitoring Unix systems.
- **Nginx:** A reverse proxy.
- **Prometheus Exporters:** Exporters for Nginx and Node.
- **Wazuh Agent:** A security monitoring agent.

### `vm-monitor`

This virtual machine is dedicated to monitoring the other hosts and services.

#### Services

- **Beszel:** A messaging service (hub and agent).
- **Monit:** A utility for managing and monitoring Unix systems.
- **Nginx:** A reverse proxy.
- **Prometheus:** A monitoring and alerting toolkit (server and exporters).
- **Wazuh:** A security monitoring platform (server and agent).

### `vm-security`

This virtual machine is set up as a security-focused desktop environment, with a variety of tools for penetration testing, forensics, and reverse engineering.

#### Desktop Environment

- **LXQt:** A lightweight Qt desktop environment.
- **Catppuccin:** A soothing pastel theme.

#### Security Tools

- **Recon & Networking:** `nmap`, `masscan`, `netcat`, `socat`, `tcpdump`, `tshark`
- **Web Security:** `burpsuite`, `sqlmap`, `nikto`, `gobuster`, `dirb`, `whatweb`
- **Passwords & Auth:** `john`, `hashcat`, `hydra`, `medusa`
- **Exploitation:** `metasploit`, `exploitdb`
- **Forensics:** `binwalk`, `file`, `xxd`, `jq`, `steghide`, `exiftool`, `binsider`, `zsteg`
- **Utilities:** `unzip`, `unrar`, `ouch`, `lazynmap`

## Secret Management (agenix)

Secrets are managed declaratively and securely using `agenix`.

- **Encryption:** Secrets are encrypted using `age` and stored as `.age` files in the `secrets/` directory.
- **Decryption:** Each host is configured to decrypt secrets at build time. The `age.identityPaths` option in each host's configuration points to the host's SSH private key, which is used for decryption.
- **Declaration:** The `secrets/secrets.nix` file maps each secret file to the public key(s) that can encrypt it.
- **Usage:** Modules that require secrets reference the decrypted path via `config.age.secrets.<secret-name>.path`.

## Build & Deployment

The configurations can be built and deployed using `nixos-rebuild` or `colmena`.

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
