{ config, ... }:
{
  imports = [
    ../files
  ];

  age.secrets = {
    mcp-config = {
      file = ../../secrets/mcp-config.age;
      path = "${config.home.homeDirectory}/.gemini/config/mcp_config.json";
    };
    opencode-config = {
      file = ../../secrets/opencode-config.age;
      path = "${config.home.homeDirectory}/.config/opencode/opencode.jsonc";
    };
  };

  custom.home = {
    dotfiles = {
      enable = true;
      role = "workstation";
      host = "arch";
    };
  };
}
