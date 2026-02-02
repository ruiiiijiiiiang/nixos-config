# GEMINI.md

## Project Overview

This repository contains a comprehensive NixOS configuration managed using Nix Flakes. It defines the configurations for multiple hosts, ranging from physical hardware like a Framework laptop and Raspberry Pi to specialized virtual machines. The project emphasizes a declarative, reproducible, and secure setup, leveraging various tools and custom modules to manage services, secrets, and deployments.

The project is structured to share common configurations across hosts while allowing for specific overrides and additions. It integrates Home Manager for user-level configuration and uses `agenix` for secure secret management.

## Project Structure

The repository is organized into several key directories:

- `homes/`: Contains Home Manager configurations for users (e.g., `rui`, `vm-security`).
- `hosts/`: Defines host-specific NixOS configurations.
  - `framework/`: Configuration for a Framework laptop (GUI, physical).
  - `pi/`: Configuration for a Raspberry Pi (Server, physical).
  - `vm-app/`: Dedicated to application hosting (GPU Passthrough enabled).
  - `vm-network/`: Acts as the central software router (DHCP, DNS, VPN, IPS).
  - `vm-monitor/`: dedicated to system and security monitoring.
  - `vm-security/`: Specialized security and forensics environment.
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

## Self-Hosted Services

The `modules/services/apps/` directory contains configurations for numerous services, organized by domain:

- **Media:** Immich, Jellyfin (GPU accelerated)
- **Office:** Opencloud, Paperless-ngx, Stirling-PDF, Memos, Nextcloud
- **Tools:** Atuin, MicroBin, Syncthing, Home Assistant, Forgejo, LLM (Ollama + Open WebUI - GPU accelerated), SearXNG
- **Security:** Vaultwarden, PocketID
- **Web:** Homepage, Website
