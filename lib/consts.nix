rec {
  timeZone = "America/Chicago";
  defaultLocale = "en_US.UTF-8";
  username = "rui";
  home = "/home/${username}";

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
      pihole = "pihole";
    };
    vm-app = {
      lidarr = "lidarr";
      radarr = "radarr";
      sonarr = "sonarr";
      prowlarr = "prowlarr";
      bazarr = "bazarr";
      atuin = "atuin";
      bytestash = "stash";
      dawarich = "dawarich";
      bentopdf = "pdf";
      forgejo = "git";
      homepage = "home";
      immich = "immich";
      jellyfin = "jellyfin";
      karakeep = "karakeep";
      memos = "memos";
      microbin = "bin";
      nextcloud = "nextcloud";
      onlyoffice = "office";
      opencloud = "opencloud";
      openwebui = "llm";
      paperless = "paperless";
      pocketid = "id";
      portainer = "portainer";
      public = "public";
      qbittorrent = "qbittorrent";
      reitti = "reitti";
      searxng = "searxng";
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
      myspeed = "myspeed";
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
      dhcp-min = "192.168.2.50";
      dhcp-max = "192.168.2.250";
      hosts = {
        vm-network = "192.168.2.1";
        framework = "192.168.2.10";
        arch = "192.168.2.11";
      };
    };
    infra = {
      network = "192.168.20.0/24";
      dhcp-min = "192.168.20.100";
      dhcp-max = "192.168.20.250";
      hosts = {
        vm-network = "192.168.20.1";
        vm-app = "192.168.20.2";
        vm-monitor = "192.168.20.3";
        pi = "192.168.20.51";
        pi-legacy = "192.168.20.52";
        proxmox = "192.168.20.254";
      };
      vip = {
        dns = "192.168.20.53";
      };
    };
    dmz = {
      network = "192.168.88.0/24";
      dhcp-min = "192.168.88.50";
      dhcp-max = "192.168.88.250";
      hosts = {
        vm-network = "192.168.88.1";
        vm-security = "192.168.88.10";
      };
    };
    vpn = {
      network = "10.5.5.0/24";
      hosts = {
        vm-network = "10.5.5.1";
        framework = "10.5.5.2";
        iphone-16 = "10.5.5.3";
        iphone-17 = "10.5.5.4";
        github-action = "10.5.5.5";
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
    ssh = 22;
    dns = 53;
    dhcp = 67;
    http = 80;
    https = 443;

    arr = {
      lidarr = 8686;
      radarr = 7878;
      sonarr = 8989;
      prowlarr = 9696;
      bazarr = 6767;
      flaresolverr = 8191;
    };
    atuin = 8888;
    bentopdf = 8080;
    bytestash = 5000;
    forgejo = {
      ssh = 2222;
      server = 3004;
    };
    beszel = {
      hub = 8090;
      agent = 45876;
    };
    dawarich = 3000;
    dockhand = {
      server = 3003;
      agent = 2376;
    };
    gatus = 8083;
    grafana = 3001;
    homeassistant = 8123;
    homepage = 8089;
    karakeep = 8084;
    kea = {
      ctrl-agent = 8002;
    };
    immich = 2283;
    jellyfin = 8096;
    memos = 5230;
    microbin = 8088;
    monit = 2812;
    myspeed = 5216;
    nginx = {
      stub = 8082;
    };
    ollama = 11434;
    onlyoffice = 8001;
    opencloud = 9201;
    openwebui = 8087;
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
        kea = 9547;
        nginx = 9113;
        node = 9100;
        podman = 9882;
      };
    };
    proxmox = 8006;
    qbittorrent = 8086;
    redis = 6379;
    reitti = 8085;
    scanopy = {
      server = 60072;
      daemon = 60073;
    };
    searxng = 8092;
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

  oci-uids = {
    podman = 899;
    immich = 900;
    paperless = 901;
    opencloud = 902;
    karakeep = 903;
    memos = 904;
    reitti = 905;
    dawarich = 906;
    arr = 907;
    qbittorrent = 908;
    jellyfin = 909;
    dockhand = 910;
    scanopy = 911;
    bytestash = 912;
    forgejo = 913;
    llm = 914;
    searxng = 915;
    atuin = 916;
    user = 1000;
    nobody = 65534;

    postgres = 999;
    postgres-alpine = 70;
  };

  oidc-issuer = "${subdomains.vm-app.pocketid}.${domains.home}";
  vpn-endpoint = "vpn.${domains.home}";
}
