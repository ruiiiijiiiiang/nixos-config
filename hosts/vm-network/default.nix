{
  imports = [
    ../../modules
    ./router.nix
  ];

  system.stateVersion = "25.11";
  networking.hostName = "vm-network";

  custom = {
    server = {
      network.enable = true;
      security.enable = true;
      services.enable = true;
    };

    vm = {
      hardware.enable = true;
      disks = {
        enableMain = true;
        enableStorage = true;
      };
    };

    selfhost = {
      dns.enable = true;
      dyndns.enable = true;
      nginx.enable = true;

      beszel.agent.enable = true;
      dockhand.agent.enable = true;
      prometheus.exporters = {
        nginx.enable = true;
        node.enable = true;
      };
      scanopy.daemon.enable = true;
      suricata = {
        enable = true;
        interfaces = [
          "ens18"
          "ens19"
        ];
      };
      wazuh.agent.enable = true;
    };
  };
}
