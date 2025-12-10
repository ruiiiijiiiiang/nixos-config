# NixOS Configuration

This repository contains the NixOS configurations for several hosts, managed using Nix Flakes.

## Host: Raspberry Pi (`pi`)

This configuration manages a Raspberry Pi 4 setup for self-hosting various services. It's designed to be secure, efficient, and easily reproducible.

### Services

The following services are enabled on the Raspberry Pi:

- **Nginx:** A high-performance web server, acting as a reverse proxy for all other web services.
- **Home Assistant:** A home automation platform that puts local control and privacy first. It runs in a Podman container.
- **Z-Wave JS UI:** A control panel and server for Z-Wave networks, used in conjunction with Home Assistant. It runs in a Podman container.
- **Vaultwarden:** An unofficial Bitwarden password manager server written in Rust.
- **Pi-hole:** A network-level advertisement and internet tracker blocking application which acts as a DNS sinkhole.
- **Unbound:** A validating, recursive, and caching DNS resolver that forwards queries from Pi-hole via DNS-over-TLS for enhanced privacy.
- **Cloudflared:** A daemon for Cloudflare Tunnel, providing secure outbound connections to the Cloudflare network for exposing services.
- **Syncthing:** A continuous file synchronization program.
- **Microbin:** A small, simple, and secure pastebin service.
- **Atuin:** A tool for syncing, searching, and managing shell history.
- **Monit:** A utility for managing and monitoring Unix systems.
- **Podman:** A container engine for developing, managing, and running OCI Containers.
- **ACME:** Automated SSL certificate management using Let's Encrypt to provide HTTPS for all web services.
- **Fail2Ban:** An intrusion prevention software framework that protects computer servers from brute-force attacks.

### Networking

The networking is configured with security and local DNS resolution in mind.

- **Firewall:** The firewall is managed by `nixos-fw` and allows incoming traffic on the following ports:
  - `22/tcp` (SSH)
  - `80/tcp` (HTTP, for ACME challenges and redirection to HTTPS)
  - `443/tcp` (HTTPS)
- **Internal Access:** Custom firewall rules, defined using `networking.firewall.extraCommands`, are in place to explicitly allow access to Home Assistant's port only from the predefined local home network and the VPN network. This enhances security by limiting direct exposure.

- **DNS:**
  1.  Clients on the network use Pi-hole for DNS resolution, which provides ad-blocking.
  2.  Pi-hole forwards DNS queries to a local Unbound instance.
  3.  Unbound resolves queries by forwarding them to Quad9's DNS servers using DNS-over-TLS, preventing ISP snooping.
- **External Access:** Services are exposed to the internet securely via a Cloudflare Tunnel, managed by the `cloudflared` service. This avoids opening multiple ports on the firewall.
- **VPN Access:** A local router runs a WireGuard VPN server, allowing mobile devices (phones, laptops, etc.) to securely reach the home network.

### Reverse Proxy (Nginx)

Nginx is used as a reverse proxy to route traffic to the appropriate service based on the hostname. All services are served over HTTPS, with SSL certificates automatically provisioned by the ACME module.

Access to the services is restricted at the Nginx level to the local home network and the VPN network.

Here is the proxy configuration:

| Subdomain   | Proxies to                        |
| ----------- | --------------------------------- |
| `ha`        | `localhost:8123` (Home Assistant) |
| `zwave`     | `localhost:8091` (Z-Wave JS UI)   |
| `vault`     | `localhost:8080` (Vaultwarden)    |
| `pihole`    | `localhost:8082` (Pi-hole Web UI) |
| `syncthing` | `localhost:8384` (Syncthing)      |
| `microbin`  | `localhost:8088` (Microbin)       |
| `monit`     | `localhost:2812` (Monit)          |

### Secret Management (agenix)

Secrets are managed declaratively and securely using `agenix`.

- **Encryption:** Secrets are encrypted using `age` and stored as `.age` files in the `secrets/` directory.
- **Decryption:** The `pi` host is configured to decrypt secrets at build time. The `age.identityPaths` option in `systems/pi/default.nix` points to the host's SSH private key (`/home/rui/.ssh/id_ed25519`), which is used for decryption.
- **Declaration:** The `secrets/secrets.nix` file maps each secret file to the public key(s) that can encrypt it. For the `pi` host, this is the `rui-nixos-pi` SSH key.
- **Usage:** Modules that require secrets, like `vaultwarden`, reference the decrypted path via `config.age.secrets.<secret-name>.path`. For example:
  ```nix
    # modules/vaultwarden/default.nix
    services.vaultwarden = {
      environmentFile = config.age.secrets.vaultwarden-env.path;
    };
  ```
  This setup ensures that secrets are never stored in plain text in the Nix store and that only the target host can decrypt them.

### Build & Deployment

Deployment is automated via a GitHub Actions workflow, which can be triggered manually.

The workflow performs the following steps:

1.  **Cross-Compilation Setup:** It sets up QEMU to enable building for the `aarch64-linux` architecture on an `x86_64` runner.
2.  **Connect to Home Network:** The runner establishes a secure connection to the home network by setting up and activating a WireGuard VPN client. The VPN configuration is stored securely in GitHub secrets.
3.  **SSH Access:** An SSH private key, also stored in secrets, is loaded into the `ssh-agent`. This allows the runner to authenticate with the Raspberry Pi.
4.  **Deploy Configuration:** Finally, the workflow executes the `nixos-rebuild switch` command. This command builds the NixOS configuration for the `rui-nixos-pi` host from the flake, and then deploys it to the target Raspberry Pi over SSH.
