{
  config,
  consts,
  lib,
  pkgs,
  ...
}:
let
  inherit (consts) username;
  cfg = config.custom.roles.workstation.development.homelab-mount;
  hosts = [
    "vm-app"
    "vm-network"
    "vm-monitor"
  ];

  localBaseDir = "/mnt/homelab";

  mkSshMounts = host: {
    mount = {
      description = "Mount ${host} via SSHFS";
      what = "${username}@${host}:/";
      where = "${localBaseDir}/${host}";
      type = "fuse.sshfs";
      options = "_netdev,allow_other,default_permissions,IdentityFile=/home/${username}/.ssh/id_ed25519,UserKnownHostsFile=/home/${username}/.ssh/known_hosts,reconnect,ServerAliveInterval=15,ServerAliveCountMax=3";
    };
    automount = {
      description = "Automount ${host}";
      where = "${localBaseDir}/${host}";
      automountConfig.TimeoutIdleSec = "300";
      wantedBy = [ "multi-user.target" ];
    };
  };

  allMounts = builtins.map mkSshMounts hosts;
in
{
  options.custom.roles.workstation.development.homelab-mount = with lib; {
    enable = mkEnableOption "Enable homelab mount";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.sshfs ];

    systemd = {
      tmpfiles.rules = [
        "d ${localBaseDir} 0755 ${username} users -"
      ]
      ++ (builtins.map (h: "d ${localBaseDir}/${h} 0755 ${username} users -") hosts);

      mounts = builtins.map (m: m.mount) allMounts;
      automounts = builtins.map (m: m.automount) allMounts;
    };
  };
}
