# GEMINI.md

## Project Overview

This repository contains a comprehensive NixOS configuration managed using Nix Flakes. It defines the configurations for multiple hosts, ranging from physical hardware like a Framework laptop and Raspberry Pi to specialized virtual machines. The project emphasizes a declarative, reproducible, and secure setup, leveraging various tools and custom modules to manage services, secrets, and deployments.

The project is structured to share common configurations across hosts while allowing for specific overrides and additions. It integrates Home Manager for user-level configuration and uses `agenix` for secure secret management.

## Project Structure

The repository is organized into several key directories:

*   `homes/`: Contains Home Manager configurations for users (e.g., `rui`, `vm-security`).
*   `hosts/`: Defines host-specific NixOS configurations.
    *   `common/`: Shared NixOS modules and settings used by multiple hosts.
    *   `framework/`: Configuration for a Framework laptop (GUI, physical).
    *   `pi/`: Configuration for a Raspberry Pi (Server, physical).
    *   `vm-app/`, `vm-monitor/`, `vm-network/`, `vm-security/`: Specialized virtual machine configurations.
*   `modules/`: Custom NixOS modules for various services and features.
    *   `selfhost/`: A wide array of self-hosted services (e.g., Immich, Nextcloud, Paperless-ngx, Wazuh, etc.).
    *   `devops/`: DevOps-related tools like K3s.
    *   `flatpak/`: Flatpak integration.
    *   `catppuccin/`: Theming modules.
*   `lib/`: Utility functions and constants used throughout the configuration.
*   `secrets/`: Encrypted secrets managed by `agenix`.
*   `shells/`: Custom development shells (e.g., `rust`, `devops`, `forensics`).

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

*   **Nix Flakes:** Ensures reproducible builds and manages external dependencies.
*   **Secret Management:** `agenix` (encrypted with `age`) is used to manage sensitive data securely within the git repository.
*   **Containerization:** Services are primarily managed via Podman using the `virtualisation.oci-containers` NixOS option.
*   **Networking:** Secure access is facilitated through Cloudflare Tunnels and Caddy/Nginx reverse proxies.
*   **Theming:** The project uses Catppuccin for consistent styling across various applications and environments.
*   **CI/CD:** Automated deployment to the Raspberry Pi is handled via GitHub Actions.

## Self-Hosted Services

The `modules/selfhost/` directory contains configurations for numerous services, including:
- **Media & Photos:** Immich
- **Cloud & Productivity:** Nextcloud, Paperless-ngx, Stirling-PDF, Vaultwarden
- **Monitoring & Security:** Beszel, Gatus, Prometheus, Wazuh
- **Utilities:** Atuin, MicroBin, Syncthing, Home Assistant
- **Web:** Caddy, Nginx, Cloudflared