{ config, ... }:
let
  hasNginxVirtualHosts = config.services.nginx.virtualHosts != { };
  hasOciContainers = config.virtualisation.oci-containers.containers != { };
in
{
  imports = [
    ./apps
    ./infra
    ./networking
    ./observability
    ./security
  ];

  assertions = [
    {
      assertion = (!hasNginxVirtualHosts) || config.custom.services.networking.nginx.enable;
      message = "Nginx virtual hosts are defined but custom.services.networking.nginx.enable is false.";
    }
    {
      assertion = (!hasOciContainers) || config.virtualisation.podman.enable;
      message = "OCI containers are defined but virtualisation.podman.enable is false.";
    }
  ];
}
