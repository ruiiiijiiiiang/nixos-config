let
  text = /* markdown */ ''
    # AI Agent Global Rules

    ## Available Hosts & Infrastructure Layout
    - **`framework` / `desktop`**: Personal GUI workstations.
    - **`hypervisor`**: Mini PC libvirt hypervisor host. Manages all VMs via NixVirt and hosts Cockpit for virtual machine management.
    - **`pi`**: Physical Raspberry Pi 4 handling IoT/smart home services (Home Assistant, Z-Wave) and secondary DNS backup.
    - **`vm-network`**: Central router & gateway. Manages WAN/LAN routing, WireGuard VPN, primary DNS, DNS resolution logs, and network monitoring (NetAlertX).
    - **`vm-app`**: Main internal application host. Manages identity/auth (PocketID, Vaultwarden), dev tools (Forgejo, Atuin, ByteStash), media stack (Jellyfin, Immich, *arr), cloud storage (OpenCloud, Paperless), and AI services (LibreChat).
    - **`vm-monitor`**: Observability & monitoring hub. Aggregates metrics and logs; runs Grafana, Loki (central log repository), Prometheus, Wazuh SIEM, Gatus uptime checks, and Ntfy notifications.
    - **`vm-public`**: DMZ node for public-facing services exposed via Cloudflare Tunnels (SearXNG, MicroBin, personal website, Zeroclaw).
    - **`vm-cyber`**: Isolated security research environment equipped with cyber security toolsets and SPICE GUI access.

    ## Environment Assumptions
    - **Host Environment:** Unless otherwise specified, an AI agent may assume to be running on either the `framework` or `desktop` host.
    - **NixOS Infrastructure:** All infrastructure is declared using `nixos-config`. This repo should normally be available locally at `~/nixos-config`; if not, refer to its GitHub repository at https://github.com/ruiiiijiiiiang/nixos-config.
    - **User Dotfiles:** The dotfiles for both systems are symlinked using `home-manager`. This repo should normally be available locally at `~/dotfiles`; if not, refer to its GitHub repository at https://github.com/ruiiiijiiiiang/dotfiles.
    - **SSH Access:** Unless otherwise specified, an AI agent may assume to have SSH access into any of the servers above.
    - Note: All hosts use the `fish` shell by default.

    ## Tool Preferences
    - **Web Search:** When performing web searches, always use the `searxng` MCP server tool (`searxng_web_search`) instead of the built-in `search_web` tool.
    - **Grafana Logs:** When retrieving logs, use the `grafana` MCP server to query the Grafana server deployed on `vm-monitor`.

    ## Investigation and Modification Rules
    - **Strict Investigation & Modification Flow:** When tasked to investigate an issue, the agent must always report findings first and present a proposed solution. Under no circumstances should the agent update any codebase or configuration files directly without receiving explicit manual confirmation from the user for the proposed changes.
    - **Read-Only Investigation:** Regardless of the host OS, stick to read-only commands during an investigation. No modification of the running system state or configuration files can happen without manual confirmation.
    - **Experimental Modifications:** If experiments with temporary modifications are required to conduct deeper research, the agent must explicitly lay out the anticipated effects and a step-by-step restoration plan beforehand.
  '';
in
{
  home.file = {
    ".gemini/config/AGENTS.md".text = text;
    ".codex/AGENTS.md".text = text;
    ".config/opencode/AGENTS.md".text = text;
    ".copilot/copilot-instructions.md".text = text;
  };
}
