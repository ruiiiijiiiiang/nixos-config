{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.home) homeDirectory;
  cfg = config.custom.home.memory;
  package = inputs.infrastructure-memory.packages.${pkgs.stdenv.hostPlatform.system}.default;
  settingsPath = "${config.xdg.configHome}/infrastructure-memory/config.json";
  statePath = "${config.xdg.stateHome}/infrastructure-memory";
  command = pkgs.writeShellApplication {
    name = "infra-memory";
    text = /* bash */ ''
      if [ -z "''${INFRA_MEMORY_CONFIG:-}" ]; then
        export INFRA_MEMORY_CONFIG=${lib.escapeShellArg settingsPath}
      fi
      exec ${lib.getExe package} "$@"
    '';
  };
in
{
  options.custom.home.memory = {
    enable = lib.mkEnableOption "workstation-local infrastructure memory";
    semanticSearch = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Use the pinned local embedding model when it has been downloaded manually.";
    };
    repositories = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            name = lib.mkOption { type = lib.types.str; };
            path = lib.mkOption { type = lib.types.str; };
            include = lib.mkOption { type = lib.types.listOf lib.types.str; };
          };
        }
      );
      default = [
        {
          name = "nixos-config";
          path = "${homeDirectory}/nixos-config";
          include = [
            "hosts/*.nix"
            "lib/consts.nix"
            "lib/helpers.nix"
            "modules/services/*.nix"
            "homes/modules/memory.nix"
            "homes/configs/*.nix"
            "topology/*.d2"
            "README.md"
            "docs/infrastructure-memory.md"
          ];
        }
      ];
      description = "Explicit allowlists of tracked local repository files to index.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ command ];

    xdg.configFile = {
      "infrastructure-memory/config.json".text = builtins.toJSON {
        records = "${homeDirectory}/infrastructure-memory/records";
        state = statePath;
        cache = "${config.xdg.cacheHome}/infrastructure-memory";
        inherit (cfg) repositories;
        semantic = cfg.semanticSearch;
        interval = 15;
        # The application derives the socket from XDG_RUNTIME_DIR at runtime.
      };
      "infrastructure-memory/mcp.json".text = builtins.toJSON {
        mcpServers.infrastructure-memory = {
          command = lib.getExe command;
          args = [ "mcp" ];
        };
      };
    };

    systemd.user.services.infrastructure-memory = {
      Unit.Description = "Local infrastructure memory and immutable record importer";
      Install.WantedBy = [ "default.target" ];
      Service = {
        ExecStart = "${lib.getExe command} serve";
        Environment = [
          "HF_HUB_OFFLINE=1"
          "TOKENIZERS_PARALLELISM=false"
          "OMP_NUM_THREADS=2"
        ];
        Restart = "on-failure";
        RestartSec = 5;
        UMask = "0077";
        RuntimeDirectory = "infrastructure-memory";
        RuntimeDirectoryMode = "0700";
        NoNewPrivileges = true;
        RestrictAddressFamilies = [ "AF_UNIX" ];
        InaccessiblePaths = [ "-${statePath}/keys/operator.key" ];
        MemoryHigh = "2G";
        MemoryMax = "3G";
        CPUQuota = "200%";
      };
    };
  };
}
