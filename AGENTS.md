# AI Agent Project Context: nixos-config

## Project Overview

This repository contains a fully declarative and reproducible NixOS configuration for a personal homelab, managed via **Nix Flakes**. It follows a **Domain-Driven Design** architecture, organizing system components into four composable layers.

- **Foundational Stack:** NixOS, Nix Flakes, `flake-parts`.
- **Infrastructure Management:** `disko` (disk partitioning), `agenix` (secret management), `NixVirt` (libvirt virtualization).
- **Home Environment:** `home-manager` for user-specific configurations and dotfiles.
- **Hardware:** Framework Laptop (Workstation), Raspberry Pi 4 (IoT/DNS), and a Mini PC (Hypervisor) running multiple specialized VMs.
- **Domain Info:** The primary domain `ruijiang.me` is purchased through Namecheap (expires annually on June 28th), but all DNS records for the domain and its subdomains are handled by Cloudflare.

## Directory Structure Highlights

- `homes/`: Home-manager configurations and modules.
- `hosts/`: Host-specific NixOS configurations and flake-module entry point.
- `lib/`: Shared constants and helper functions.
- `modules/`: The core of the NixOS modular system (core, platforms, roles, services).
- `secrets/`: Encrypted secrets (agenix).
- `shells/`: Development shells defined as flakes.

### Architectural Layers (`modules/`)

1. **core:** Universal system baselines (networking, users, core packages).
2. **platforms:** Hardware-specific abstractions and disk layouts (Framework, Pi, VM).
3. **roles:** Host "personalities" (Workstation, Headless Server, Cyber Research).
4. **services:** Functional applications categorized by domain (apps, infra, networking, observability, security).

## Deployment and Build Rules

- **Explicit Command Ban:** Under no circumstances should an AI agent attempt to run commands involving `nix build`, `nixos-rebuild`, or any other Nix build/deployment tools (including remote execution over SSH). The only exception is `nix eval`, which agents are explicitly allowed to execute for inspecting attribute values and expressions.
- **Strictly Manual Deployments:** All building, testing, and deployments are handled manually by the user. The agent's output is strictly limited to making configuration changes.
- **Strict Investigation & Modification Flow:** When tasked to investigate an issue, the agent must always report findings first and present a proposed solution. Under no circumstances should the agent update any codebase or configuration files directly without receiving explicit manual confirmation from the user for the proposed changes.

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
- **Native Module Options over `extraOptions`:** Whenever there is a need to add raw configuration flags to a container using `extraOptions`, always check if a native NixOS `virtualisation.oci-containers` module option exists (e.g., `hostname`, `user`, `workdir`) and prefer using the native option.

### Environment Assumptions

- **Host Environment:** Unless otherwise specified, an AI agent should assume to be running on either the `framework` or `arch` host.
- **User Dotfiles:** The dotfiles for both systems are symlinked using `home-manager` and will always be accessible to the agent at `~/dotfiles`.

### SSH Access

- Unless otherwise specified, an AI agent may always assume to have SSH access from the current host into any of the servers declared in [hosts](file:///home/rui/nixos-config/hosts).
- Note: All hosts use the `fish` shell by default.

### Centralized Constants (`lib/consts.nix`)

All network addresses, VLAN IDs, ports, subdomains, and hardware metadata are centralized in `lib/consts.nix`. **Always refer to this file when adding or modifying services.**

### Helpers (`lib/helpers.nix`)

Common logic (e.g., Nginx virtual host templates, PCI address parsing, systemd timer generators) is located in `lib/helpers.nix`.

### Secret Management

Secrets are managed using `agenix` and stored as `.age` files in the `secrets/` directory. They are decrypted at runtime by the respective hosts using SSH host keys.

### Nix Coding Style Guidelines

To maintain configuration readability and clean Nix codebase structure, the following formatting styles must be adhered to:

- **Grouped Attribute Sets:** Attribute sets should be nested/grouped together whenever possible rather than using dot-separated paths.
  - _Preferred:_ `set = { opt1 = true; opt2 = true; };`
  - _Discouraged:_ `set.opt1 = true; set.opt2 = true;`
- **Use `inherit`:** Use the `inherit` keyword whenever possible to import variables into scopes or attribute sets.
- **`with` Keyword Threshold:** The `with` keyword should be used in scopes only when the imported namespace/attribute set is referenced **more than 5 times**.
- **Syntax Highlighting in Strings:** When writing non-Nix syntax (such as YAML, Bash, or JSON) inside a Nix string, always add a language comment (e.g., `/* yaml */`, `/* bash */`) in front of the string to ensure proper syntax highlighting in editors.
  - _Example:_ `settingsFile = pkgs.writeText "settings.yml" /* yaml */ ''...'';`
- **Code Formatting:** Always use `nixfmt` to clean up and format Nix code after editing.
