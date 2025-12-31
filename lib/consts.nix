{
  timeZone = "America/Chicago";
  defaultLocale = "en_US.UTF-8";

  # please don't DDOS :)
  domains = {
    home = "ruijiang.me";
    tplink = "ruijiang.tplinkdns.com";
  };

  subdomains = {
    pi = {
      homeassistant = "ha";
      monit = "pi-monit";
      pihole = "pi-pihole";
      zwave = "zwave";
    };
    vm-network = {
      pihole = "pihole";
      monit = "vm-network-monit";
    };
    vm-app = {
      atuin = "atuin";
      bentopdf = "pdf";
      dawarich = "gps";
      immich = "immich";
      homepage = "home";
      microbin = "bin";
      monit = "vm-app-monit";
      nextcloud = "nextcloud";
      onlyoffice = "office";
      paperless = "paperless";
      pocketid = "id";
      portainer = "portainer";
      public = "public";
      syncthing = "syncthing";
      vaultwarden = "vault";
      yourls = "url";
    };
    vm-monitor = {
      beszel = "beszel";
      grafana = "grafana";
      monit = "vm-monitor-monit";
      prometheus = "prometheus";
      wazuh = "wazuh";
    };
  };

  addresses = {
    any = "0.0.0.0";
    localhost = "127.0.0.1";
    localhost-v6 = "::1";
    home = {
      network = "192.168.68.0/24";
      hosts = {
        arch = "192.168.68.74";
        pi = "192.168.68.80";
        framework = "192.168.68.85";
        proxmox = "192.168.68.100";
        vm-network = "192.168.68.87";
        vm-app = "192.168.68.89";
        vm-monitor = "192.168.68.90";
        pi-legacy = "192.168.68.83";
      };
    };
    vpn = {
      network = "10.0.0.0/8";
      hosts = {
        iphone = "10.5.5.2";
        framework = "10.5.5.4";
      };
    };
  };

  ports = {
    atuin = 8888;
    bentopdf = 8080;
    beszel = {
      hub = 8090;
      agent = 45876;
    };
    dawarich = 3000;
    grafana = 3001;
    homeassistant = 8123;
    homepage = 8089;
    immich = 2283;
    microbin = 8088;
    monit = 2812;
    nginx = {
      stub = 8082;
    };
    oauth2 = 4180;
    onlyoffice = 8001;
    paperless = 28981;
    pihole = 8008;
    pocketid = 1411;
    portainer = {
      server = 9000;
      edge = 8000;
    };
    prometheus = {
      server = 9090;
      exporters = {
        nginx = 9113;
        node = 9100;
        podman = 9882;
      };
    };
    proxmox = 8006;
    redis = 6379;
    syncthing = 8384;
    unbound = 5335;
    vaultwarden = {
      server = 8222;
      websocket = 3012;
    };
    wazuh = {
      indexer = 9200;
      manager = 55000;
      dashboard = 5601;
      agent = {
        connection = 1514;
        enrollment = 1515;
      };
    };
    website = 8964;
    wireguard = 51820;
    yourls = 8081;
    zwave = 8091;
  };
}
