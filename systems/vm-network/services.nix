{ ... }:

{
  rui = {
    acme.enable = true;
    dns = {
      enable = true;
      subdomain = "pihole";
    };
    monit = {
      enable = true;
      subdomain = "vm-network-monit";
    };
    nginx.enable = true;
  };
}
