let
  text = /* markdown */ ''
    # AI Agent Global Rules

    ## Environment Assumptions
    - **Host Environment:** Unless otherwise specified, an AI agent should assume to be running on either the `framework` or `desktop` host.
    - **NixOS Infrastructure:** All infrastructure is declared using `nixos-config`. This repo should normally be available locally at `~/nixos-config`; if not, refer to its GitHub repository at https://github.com/ruiiiijiiiiang/nixos-config.
    - **User Dotfiles:** The dotfiles for both systems are symlinked using `home-manager`. This repo should normally be available locally at `~/dotfiles`; if not, refer to its GitHub repository at https://github.com/ruiiiijiiiiang/dotfiles.

    ## Tool Preferences
    - **Web Search:** When performing web searches, always use the `searxng` MCP server tool (`searxng_web_search`) instead of the built-in `search_web` tool.
    - **Grafana Logs:** When retrieving logs, use the `grafana` MCP server to query the Grafana server deployed on `vm-monitor`.

    ## SSH Access
    - Unless otherwise specified, an AI agent may always assume to have SSH access from the current host into any of the servers declared in `nixos-config/hosts`.
    - Note: All hosts use the `fish` shell by default.

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
