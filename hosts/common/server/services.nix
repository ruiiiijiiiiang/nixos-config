{ inputs, pkgs, ... }:
with inputs;
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

  environment.systemPackages = with pkgs; [
    agenix.packages.${stdenv.system}.default
  ];
}
