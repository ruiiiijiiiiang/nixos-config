{ inputs, pkgs, ... }:
{
  virtualisation = {
    oci-containers = {
      backend = "podman";
    };
    podman = {
      enable = true;
      dockerCompat = true;
      dockerSocket.enable = true;
      autoPrune = {
        enable = true;
        dates = "weekly";
        flags = [ "--all" ];
      };
    };
  };

  systemd.tmpfiles.rules = [
    "L+ /var/run/docker.sock - - - - /run/podman/podman.sock"
  ];

  services = {
    logrotate.enable = true;
    journald.extraConfig = ''
      SystemMaxUse=1G
      Storage=persistent
    '';

    xserver.enable = false;
    avahi.enable = false;
    printing.enable = false;
  };

  environment.systemPackages = [
    inputs.agenix.packages.${pkgs.stdenv.system}.default
  ];
}
