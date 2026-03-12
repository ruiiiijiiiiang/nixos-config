{
  config,
  consts,
  inputs,
  lib,
  ...
}:
let
  inherit (consts) username;
  inherit (inputs.self) nixosConfigurations;
  cfg = config.custom.services.infra.nfs.client;

  localBaseDir = "/mnt/homelab";

  mkNfsMounts = host: {
    mount = {
      description = "NFS Mount for ${host}";
      what = "${host}:/";
      where = "${localBaseDir}/${host}";
      type = "nfs";
      options = "rw,soft,rsize=1048576,wsize=1048576,timeo=14,retrans=2,_netdev";
    };
    automount = {
      description = "Automount for ${host}";
      where = "${localBaseDir}/${host}";
      wantedBy = [ "multi-user.target" ];
      automountConfig.TimeoutIdleSec = "600";
    };
  };

  allMounts = builtins.map mkNfsMounts cfg.servers;
in
{
  options.custom.services.infra.nfs.client = with lib; {
    enable = mkEnableOption "Enable NFS file client";
    servers = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "NFS servers to connect to.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion =
          let
            missing = lib.filter (host: !(lib.hasAttr host nixosConfigurations)) cfg.servers;
          in
          missing == [ ];
        message = "Unknown nixosConfigurations entries found in nfs.client.servers.";
      }
      {
        assertion = lib.all (
          host:
          (lib.hasAttr host nixosConfigurations)
          && (nixosConfigurations.${host}.config.custom.services.infra.nfs.server.enable or false)
        ) cfg.servers;
        message = "Every NFS client server entry must enable custom.services.infra.nfs.server.";
      }
    ];

    boot.supportedFilesystems = [ "nfs" ];

    systemd = {
      tmpfiles.rules = [
        "d ${localBaseDir} 0755 ${username} users -"
      ]
      ++ (builtins.map (h: "d ${localBaseDir}/${h} 0755 ${username} users -") cfg.servers);

      mounts = builtins.map (m: m.mount) allMounts;
      automounts = builtins.map (m: m.automount) allMounts;
    };
  };
}
