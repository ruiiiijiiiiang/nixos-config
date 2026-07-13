{
  home.file.".gemini/config/AGENTS.md".text = /* markdown */ ''
    # AI Agent Global Rules

    ## Tool Preferences
    - **Web Search:** When performing web searches, always use the `searxng` MCP server tool (`searxng_web_search`) instead of the built-in `search_web` tool.

    ## Investigation and Modification Rules
    - **Strict Investigation & Modification Flow:** When tasked to investigate an issue, the agent must always report findings first and present a proposed solution. Under no circumstances should the agent update any codebase or configuration files directly without receiving explicit manual confirmation from the user for the proposed changes.
    - **Read-Only Investigation:** Regardless of the host OS, stick to read-only commands during an investigation. No modification of the running system state or configuration files can happen without manual confirmation.
    - **Experimental Modifications:** If experiments with temporary modifications are required to conduct deeper research, the agent must explicitly lay out the anticipated effects and a step-by-step restoration plan beforehand.
  '';
}
