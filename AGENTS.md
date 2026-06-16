# AI Agent Project Context: nixos-config

## Project Overview

This repository contains a fully declarative and reproducible NixOS configuration for a personal homelab, managed via **Nix Flakes**. It follows a **Domain-Driven Design** architecture, organizing system components into four composable layers.

- **Foundational Stack:** NixOS, Nix Flakes, `flake-parts`.
- **Infrastructure Management:** `disko` (disk partitioning), `agenix` (secret management), `NixVirt` (libvirt virtualization).
- **Home Environment:** `home-manager` for user-specific configurations and dotfiles.
- **Hardware:** Framework Laptop (Workstation), Raspberry Pi 4 (IoT/DNS), and a Mini PC (Hypervisor) running multiple specialized VMs.

### Architectural Layers (`modules/`)

1. **core:** Universal system baselines (networking, users, core packages).
2. **platforms:** Hardware-specific abstractions and disk layouts (Framework, Pi, VM).
3. **roles:** Host "personalities" (Workstation, Headless Server, Cyber Research).
4. **services:** Functional applications categorized by domain (apps, infra, networking, observability, security).

## Deployment and Build Rules

- **Explicit Command Ban:** Under no circumstances should an AI agent attempt to run commands involving `nix build`, `nixos-rebuild`, or any other Nix build/deployment tools (including remote execution over SSH).
- **Strictly Manual Deployments:** All building, testing, and deployments are handled manually by the user. The agent's output is strictly limited to making configuration changes.

## Development Conventions

### Modular Configuration

- Custom NixOS options are defined under the `custom` prefix (e.g., `custom.services.apps.media.jellyfin.enable`).
- Hosts are defined in `hosts/flake-module.nix` and their individual configuration files in `hosts/`.
- Home-manager configurations are defined in `homes/flake-module.nix` and `homes/configs/`.

### OCI Container Setup Convention

Containerized services must follow these repository conventions:

- **Centralized Constants:** Declare any new subdomains, ports, and unique container UIDs in [lib/consts.nix](file:///home/rui/nixos-config/lib/consts.nix).
- **User Provisioning:** Use `helpers.mkOciUser` in the module to define a dedicated system user/group with the declared OCI UID.
- **Directory Creation:** Use `systemd.tmpfiles.rules` to create required host storage directories, assigning ownership to the OCI UID/GID.
- **Secret Management:** Manage sensitive variables in agenix. Secret preparation and agenix decryption are always handled manually by the user.
- **Network & Port Bindings:** Keep container ports bound to `localhost` (e.g., `${addresses.localhost}:${toString ports.<name>}:<container-port>`) and expose them via Nginx. For sidecar setups, configure sidecars to use network dependencies (e.g., using `networks = [ "container:<main-container>" ]` so they reuse the main container's network namespace).
- **Reverse Proxy:** Set up Nginx virtual hosts using the `helpers.mkVirtualHost` template.
- **getEnabledServices Integration:** Add the service mapping to the `getEnabledServices` helper in [lib/helpers.nix](file:///home/rui/nixos-config/lib/helpers.nix) so that enabled services can be dynamically resolved on their respective hosts.

### Environment Assumptions

- **Host Environment:** Unless otherwise specified, an AI agent should assume to be running on either the `framework` or `arch` host.
- **User Dotfiles:** The dotfiles for both systems are symlinked using `home-manager` and will always be accessible to the agent at `~/dotfiles`.

### SSH Access

- Unless otherwise specified, an AI agent may always assume to have SSH access from the current host into any of the servers declared in [hosts](file:///home/rui/nixos-config/hosts).

### Centralized Constants (`lib/consts.nix`)

All network addresses, VLAN IDs, ports, subdomains, and hardware metadata are centralized in `lib/consts.nix`. **Always refer to this file when adding or modifying services.**

### Helpers (`lib/helpers.nix`)

Common logic (e.g., Nginx virtual host templates, PCI address parsing, systemd timer generators) is located in `lib/helpers.nix`.

### Secret Management

Secrets are managed using `agenix` and stored as `.age` files in the `secrets/` directory. They are decrypted at runtime by the respective hosts using SSH host keys.

## Directory Structure Highlights

- `homes/`: Home-manager configurations and modules.
- `hosts/`: Host-specific NixOS configurations and flake-module entry point.
- `lib/`: Shared constants and helper functions.
- `modules/`: The core of the NixOS modular system (core, platforms, roles, services).
- `secrets/`: Encrypted secrets (agenix).
- `shells/`: Development shells defined as flakes.
