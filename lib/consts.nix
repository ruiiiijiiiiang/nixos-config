rec {
  timeZone = "America/Chicago";
  defaultLocale = "en_US.UTF-8";
  username = "rui";
  home = "/home/${username}";
  domain = "ruijiang.me";
  email = "me@${domain}";
  oidc-issuer = "${subdomains.vm-app.pocketid}.${domain}";
  vpn-endpoint = "vpn.${domain}";

  subdomains = {
    hypervisor = {
      cockpit = "cockpit";
    };
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
      harmonia = "cache";
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
    private-blocks = {
      class-a = "10.0.0.0/8";
      class-b = "172.16.0.0/12";
      class-c = "192.168.0.0/16";
    };
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
        hypervisor = "192.168.20.254";
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
        vm-cyber = "192.168.88.10";
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
    cockpit = 9091;
    crowdsec = {
      lapi = 8093;
    };
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
    harmonia = 5001;
    homeassistant = 8123;
    homepage = 8089;
    karakeep = 8084;
    kea = {
      ctrl-agent = 8002;
    };
    immich = 2283;
    jellyfin = 8096;
    loki = {
      server = 3100;
      agent = 3031;
    };
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
        crowdsec = 6060;
        kea = 9547;
        nginx = 9113;
        node = 9100;
        podman = 9882;
        wireguard = 9586;
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
    website = 6969;
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

  hardware = {
    uuids = {
      vm-app = "532ea825-4ca3-46a2-b15d-ba8af70ba733";
      vm-monitor = "26a3e5f9-5c4a-4956-8ee4-b680f507d3cc";
      vm-network = "2b7de5db-e0e6-4f81-b5f4-4efc928ee475";
      vm-cyber = "008d571b-aa7c-4050-96d8-7185f5ea2a95";
    };

    gpu = {
      pci = "1002:1682";
      address = "0000:e5:00.0";
    };

    storage = {
      internal = {
        nvme-ssd-0 = "nvme-WD_PC_SN810_SDCPNRY-512G-1006_23302N805496";
        nvme-ssd-1 = "nvme-Netac_NVMe_SSD_256GB_AA20251013256G327033";
      };
      external = {
        usb-hdd-0 = "ata-WDC_WD30PURX-64AKYY0_WD-WX22DB1D35NH";
        usb-hdd-1 = "ata-WDC_WD20NMVW-11EDZS7_WD-WXA1A77H0315";
      };
    };

    macs = {
      arch = "28:0c:50:9c:03:2e";
      framework = "ac:f2:3c:63:d9:f3";
      proxmox = "c8:a3:62:bf:0b:b3";
      vm-network = "bc:24:11:b0:9b:27";
      vm-app = "bc:24:11:71:f8:9b";
      vm-monitor = "bc:24:11:93:b1:94";
      vm-cyber = "bc:24:11:4b:5f:d4";
      pi = "2c:cf:67:0e:c9:6b";
      pi-legacy = "b8:27:eb:af:a2:33";
      wan = "bc:24:11:97:f8:42";
    };

    radios = {
      zigbee = "usb-1a86_USB_Serial-if00-port0";
      zwave = "usb-Silicon_Labs_CP2102N_USB_to_UART_Bridge_Controller_80edec297b57ed1193f12ef21c62bc44-if00-port0";
    };

    partitions = {
      esp = {
        priority = 1;
        name = "ESP";
        size = "512M";
        type = "EF00";
        content = {
          type = "filesystem";
          format = "vfat";
          mountpoint = "/boot";
          mountOptions = [ "umask=0077" ];
        };
      };

      root = {
        size = "100%";
        content = {
          type = "filesystem";
          format = "ext4";
          mountpoint = "/";
        };
      };
    };
  };

  vlan-ids = {
    home = 2;
    infra = 20;
    dmz = 88;
  };
}
