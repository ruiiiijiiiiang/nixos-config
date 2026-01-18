rec {
  timeZone = "America/Chicago";
  defaultLocale = "en_US.UTF-8";

  # please don't DDOS :)
  domains = {
    home = "ruijiang.me";
  };

  subdomains = {
    pi = {
      homeassistant = "ha";
      pihole = "pi-pihole";
      zwave = "zwave";
    };
    vm-network = {
      evebox = "evebox";
      pihole = "pihole";
    };
    vm-app = {
      atuin = "atuin";
      dawarich = "dawarich";
      bentopdf = "pdf";
      immich = "immich";
      homepage = "home";
      karakeep = "karakeep";
      memos = "memos";
      microbin = "bin";
      nextcloud = "nextcloud";
      onlyoffice = "office";
      opencloud = "opencloud";
      paperless = "paperless";
      pocketid = "id";
      portainer = "portainer";
      public = "public";
      reitti = "reitti";
      stirlingpdf = "pdf";
      syncthing = "syncthing";
      vaultwarden = "vault";
      yourls = "url";
    };
    vm-monitor = {
      beszel = "beszel";
      dockhand = "dockhand";
      gatus = "gatus";
      grafana = "grafana";
      prometheus = "prometheus";
      scanopy = "scanopy";
      wazuh = "wazuh";
    };
  };

  addresses = {
    any = "0.0.0.0";
    localhost = "127.0.0.1";
    localhost-v6 = "::1";
    home = {
      network = "192.168.2.0/24";
      dhcp-min = "192.168.2.100";
      dhcp-max = "192.168.2.250";
      hosts = {
        vm-network = "192.168.2.1";
        vm-app = "192.168.2.2";
        vm-monitor = "192.168.2.3";
        vm-security = "192.168.2.4";
        framework = "192.168.2.10";
        arch = "192.168.2.11";
        pi = "192.168.2.51";
        pi-legacy = "192.168.2.52";
        proxmox = "192.168.2.254";
      };
      vip = {
        dns = "192.168.2.53";
      };
    };
    vpn = {
      network = "10.5.5.0/24";
      hosts = {
        vm-network = "10.5.5.1";
        framework = "10.5.5.2";
        iphone-16 = "10.5.5.3";
        iphone-17 = "10.5.5.4";
      };
    };
    podman = {
      network = "10.88.0.0/16";
    };
  };

  macs = {
    arch = "28:0c:50:9c:03:2e";
    framework = "ac:f2:3c:63:d9:f3";
    proxmox = "c8:a3:62:bf:0b:b3";
    vm-network = "bc:24:11:b0:9b:27";
    vm-app = "bc:24:11:71:f8:9b";
    vm-monitor = "bc:24:11:93:b1:94";
    vm-security = "bc:24:11:4b:5f:d4";
    pi = "2c:cf:67:0e:c9:6b";
    pi-legacy = "b8:27:eb:af:a2:33";
  };

  ports = {
    atuin = 8888;
    bentopdf = 8080;
    beszel = {
      hub = 8090;
      agent = 45876;
    };
    dawarich = 3000;
    dhcp = 67;
    dns = 53;
    dockhand = {
      server = 3003;
      agent = 2376;
    };
    evebox = 5636;
    gatus = 8083;
    grafana = 3001;
    homeassistant = 8123;
    homepage = 8089;
    karakeep = 8084;
    immich = 2283;
    memos = 5230;
    microbin = 8088;
    monit = 2812;
    nginx = {
      stub = 8082;
    };
    oauth2 = 4180;
    onlyoffice = 8001;
    opencloud = 9201;
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
    reitti = 8085;
    scanopy = {
      server = 60072;
      daemon = 60073;
    };
    stirlingpdf = 8080;
    syncthing = 8384;
    unbound = 5335;
    uptimekuma = 3002;
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

  oidc_issuer = "${subdomains.vm-app.pocketid}.${domains.home}";
  vpn-endpoint = "vpn.${domains.home}";
}
