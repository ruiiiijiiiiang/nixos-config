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

  services = {
    logrotate.enable = true;
  };

  environment.systemPackages = [
    inputs.agenix.packages.${pkgs.stdenv.system}.default
  ];

  security.auditd.enable = true;
}
