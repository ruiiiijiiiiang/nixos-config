# GEMINI.md

## Project Overview

This repository contains a comprehensive NixOS configuration managed using Nix Flakes. It defines the configurations for multiple hosts, including a Raspberry Pi for self-hosting services, several virtual machines, and a framework laptop. The project emphasizes a declarative, reproducible, and secure setup, leveraging various tools and custom modules to manage services, secrets, and deployments.

The core of the project is the use of NixOS modules to define the configuration for each host. A common configuration is shared across all hosts, with specific configurations layered on top for each individual host. Services are often containerized using Podman and exposed to the internet securely via Cloudflare Tunnels.

## Building and Running

This project is a NixOS configuration and is not "built" in the traditional sense. Instead, the configurations are applied to the target systems using the `nixos-rebuild` command.

The `flake.nix` file defines the `nixosConfigurations` for each host. To build and switch to a new generation for a host, you would run the following command on the target machine:

```bash
nixos-rebuild switch --flake .#<hostname>
```

For example, to apply the configuration for the Raspberry Pi, you would run:

```bash
nixos-rebuild switch --flake .#pi
```

The project also uses `colmena` for remote deployment. The `flake.nix` file defines a `colmenaHive` output that can be used to deploy the configurations to the target hosts. To deploy to a specific host using colmena, you would run:

```bash
colmena apply -v --on <hostname>
```

## Development Conventions

*   **Nix Flakes:** The project uses Nix Flakes to manage dependencies and provide a reproducible build environment.
*   **Custom Modules:** The project is organized into a series of custom NixOS modules, located in the `modules/` directory. These modules are used to configure specific services and settings.
*   **Secret Management:** Secrets are managed using `agenix`, which encrypts them using `age`. The encrypted secrets are stored in the `secrets/` directory.
*   **Containerization:** Many services are containerized using Podman, which is configured via the `virtualisation.oci-containers` option in NixOS.
*   **Networking:** The network configuration is managed declaratively, with a focus on security. A firewall is configured to restrict access to services, and Cloudflare Tunnels are used to securely expose services to the internet.
*   **Reverse Proxy:** Nginx is used as a reverse proxy to route traffic to the appropriate service based on the hostname.
*   **Deployment:** Deployment to the Raspberry Pi is automated using GitHub Actions. Other hosts can be deployed to using `colmena`.
