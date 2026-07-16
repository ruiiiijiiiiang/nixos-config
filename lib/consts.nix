rec {
  timeZone = "America/Chicago";
  locale = "en_US.UTF-8";
  username = "rui";
  home = "/home/${username}";
  domain = "ruijiang.me";
  email = "me@${domain}";

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
      netalertx = "netalertx";
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
      mealie = "mealie";
      bentopdf = "pdf";
      forgejo = "git";
      harmonia = "cache";
      homepage = "home";
      immich = "immich";
      jellyfin = "jellyfin";
      karakeep = "karakeep";
      librechat = "chat";
      memos = "memos";
      magicmirror = "mirror";
      nextcloud = "nextcloud";
      onlyoffice = "office";
      opencloud = "opencloud";
      openwebui = "llm";
      paperless = "paperless";
      pocketid = "id";
      portainer = "portainer";
      ovumcy = "ovumcy";
      pricebuddy = "pricebuddy";
      qbittorrent = "qbittorrent";
      reitti = "reitti";
      stirlingpdf = "pdf";
      syncthing = "syncthing";
      vaultwarden = "vault";
      changedetection = "watch";
      yourls = "url";
    };
    vm-monitor = {
      beszel = "beszel";
      dockhand = "dockhand";
      gatus = "gatus";
      grafana = "grafana";
      myspeed = "myspeed";
      ntfy = "ntfy";
      prometheus = "prometheus";
      scanopy = "scanopy";
      termix = "termix";
      wazuh = "wazuh";
    };
    vm-public = {
      microbin = "bin";
      searxng = "searxng";
      krawl = "krawl";
      website = "public";
      zeroclaw = "zeroclaw";
    };
  };

  vlan-ids = {
    home = 2;
    infra = 20;
    dmz = 88;
    wg = 128;
  };

  addresses = {
    any = "0.0.0.0";
    any-v6 = "::";
    localhost = "127.0.0.1";
    localhost-v6 = "::1";
    home-prefix = "192.168";
    home-prefix-v6 = "fd00:0:0";
    home = {
      network = "${addresses.home-prefix}.${toString vlan-ids.home}.0/24";
      network-v6 = "${addresses.home-prefix-v6}:${toString vlan-ids.home}::/64";
      dhcp-min = "${addresses.home-prefix}.${toString vlan-ids.home}.50";
      dhcp-max = "${addresses.home-prefix}.${toString vlan-ids.home}.250";
      hosts = {
        vm-network = "${addresses.home-prefix}.${toString vlan-ids.home}.1";
        vm-network-v6 = "${addresses.home-prefix-v6}:${toString vlan-ids.home}::1";
        framework = "${addresses.home-prefix}.${toString vlan-ids.home}.10";
        framework-v6 = "${addresses.home-prefix-v6}:${toString vlan-ids.home}::10";
        desktop = "${addresses.home-prefix}.${toString vlan-ids.home}.11";
        desktop-v6 = "${addresses.home-prefix-v6}:${toString vlan-ids.home}::11";
        windows = "${addresses.home-prefix}.${toString vlan-ids.home}.12";
        windows-v6 = "${addresses.home-prefix-v6}:${toString vlan-ids.home}::12";
        pi-wifi = "${addresses.home-prefix}.${toString vlan-ids.home}.253";
        pi-wifi-v6 = "${addresses.home-prefix-v6}:${toString vlan-ids.home}::253";
        hypervisor-wifi = "${addresses.home-prefix}.${toString vlan-ids.home}.254";
        hypervisor-wifi-v6 = "${addresses.home-prefix-v6}:${toString vlan-ids.home}::254";
      };
    };
    infra = {
      network = "${addresses.home-prefix}.${toString vlan-ids.infra}.0/24";
      network-v6 = "${addresses.home-prefix-v6}:${toString vlan-ids.infra}::/64";
      dhcp-min = "${addresses.home-prefix}.${toString vlan-ids.infra}.100";
      dhcp-max = "${addresses.home-prefix}.${toString vlan-ids.infra}.250";
      hosts = {
        vm-network = "${addresses.home-prefix}.${toString vlan-ids.infra}.1";
        vm-network-v6 = "${addresses.home-prefix-v6}:${toString vlan-ids.infra}::1";
        vm-app = "${addresses.home-prefix}.${toString vlan-ids.infra}.2";
        vm-app-v6 = "${addresses.home-prefix-v6}:${toString vlan-ids.infra}::2";
        vm-monitor = "${addresses.home-prefix}.${toString vlan-ids.infra}.3";
        vm-monitor-v6 = "${addresses.home-prefix-v6}:${toString vlan-ids.infra}::3";
        pi = "${addresses.home-prefix}.${toString vlan-ids.infra}.51";
        pi-v6 = "${addresses.home-prefix-v6}:${toString vlan-ids.infra}::51";
        pi-legacy = "${addresses.home-prefix}.${toString vlan-ids.infra}.52";
        pi-legacy-v6 = "${addresses.home-prefix-v6}:${toString vlan-ids.infra}::52";
        hypervisor = "${addresses.home-prefix}.${toString vlan-ids.infra}.254";
        hypervisor-v6 = "${addresses.home-prefix-v6}:${toString vlan-ids.infra}::254";
      };
      vip = {
        dns = "${addresses.home-prefix}.${toString vlan-ids.infra}.53";
        dns-v6 = "${addresses.home-prefix-v6}:${toString vlan-ids.infra}::53";
      };
    };
    dmz = {
      network = "${addresses.home-prefix}.${toString vlan-ids.dmz}.0/24";
      network-v6 = "${addresses.home-prefix-v6}:${toString vlan-ids.dmz}::/64";
      dhcp-min = "${addresses.home-prefix}.${toString vlan-ids.dmz}.50";
      dhcp-max = "${addresses.home-prefix}.${toString vlan-ids.dmz}.250";
      hosts = {
        vm-network = "${addresses.home-prefix}.${toString vlan-ids.dmz}.1";
        vm-network-v6 = "${addresses.home-prefix-v6}:${toString vlan-ids.dmz}::1";
        vm-public = "${addresses.home-prefix}.${toString vlan-ids.dmz}.2";
        vm-public-v6 = "${addresses.home-prefix-v6}:${toString vlan-ids.dmz}::2";
        vm-cyber = "${addresses.home-prefix}.${toString vlan-ids.dmz}.10";
        vm-cyber-v6 = "${addresses.home-prefix-v6}:${toString vlan-ids.dmz}::10";
      };
    };
    wg = {
      network = "${addresses.home-prefix}.${toString vlan-ids.wg}.0/24";
      network-v6 = "${addresses.home-prefix-v6}:${toString vlan-ids.wg}::/64";
      hosts = {
        vm-network = "${addresses.home-prefix}.${toString vlan-ids.wg}.1";
        vm-network-v6 = "${addresses.home-prefix-v6}:${toString vlan-ids.wg}::1";
        framework = "${addresses.home-prefix}.${toString vlan-ids.wg}.2";
        framework-v6 = "${addresses.home-prefix-v6}:${toString vlan-ids.wg}::2";
        pixel-7 = "${addresses.home-prefix}.${toString vlan-ids.wg}.3";
        pixel-7-v6 = "${addresses.home-prefix-v6}:${toString vlan-ids.wg}::3";
        iphone-17 = "${addresses.home-prefix}.${toString vlan-ids.wg}.4";
        iphone-17-v6 = "${addresses.home-prefix-v6}:${toString vlan-ids.wg}::4";
        github-action = "${addresses.home-prefix}.${toString vlan-ids.wg}.5";
        github-action-v6 = "${addresses.home-prefix-v6}:${toString vlan-ids.wg}::5";
      };
    };
    podman = {
      network = "10.88.0.0/16";
      gateway = "10.88.0.1";
      network-v6 = "fd00:0:0:8888::/64";
      gateway-v6 = "fd00:0:0:8888::1";
    };
  };

  ports = {
    ssh = 22;
    dns = 53;
    dhcp = 67;
    http = 80;
    https = 443;
    dot = 853;
    mdns = 5353;

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
    changedetection = 5003;
    mealie = 9000;
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
    immich = 2283;
    jellyfin = 8096;
    karakeep = 8084;
    krawl = 5002;
    librechat = 3080;
    loki = {
      server = 3100;
      agent = 3031;
    };
    magicmirror = 8094;
    matter = 5540;
    memos = 5230;
    microbin = 8088;
    monit = 2812;
    myspeed = 5216;
    ntfy = 2586;
    netalertx = 8099;
    nfs = 2049;
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
    ovumcy = 8095;
    pricebuddy = 8098;
    prometheus = {
      server = 9090;
      alertmanager = 8000;
      exporters = {
        crowdsec = 6060;
        libvirt = 9177;
        nginx = 9113;
        node = 9100;
        podman = 9882;
        restic = 9753;
        smartctl = 9633;
        wireguard = 9586;
      };
    };
    qbittorrent = 8086;
    redis = 6379;
    reitti = 8085;
    scanopy = {
      server = 60072;
      daemon = 60073;
    };
    searxng = 8092;
    spice = {
      vm-cyber = 5988;
    };
    stirlingpdf = 8080;
    syncthing = 8384;
    termix = 8097;
    trivy = 9501;
    unbound = 5335;
    uptimekuma = 3002;
    vaultwarden = 8222;
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
    zeroclaw = 42617;
    zwave = 8091;
  };

  oci-uids = {
    podman = 899;
    immich = 900;
    paperless = 901;
    opencloud = 902;
    karakeep = 903;
    librechat = 904;
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
    magicmirror = 917;
    termix = 918;
    ovumcy = 919;
    krawl = 920;
    changedetection = 921;
    mealie = 922;
    pricebuddy = 923;
    netalertx = 924;
    zeroclaw = 925;
    user = 1000;
    nobody = 65534;

    postgres = 999;
    postgres-alpine = 70;
  };

  hardware = {
    gpu = {
      id = "1002:1681";
      address = "0000:e5:00.0";
    };

    nic = {
      id = "10ec:8125";
      address = "0000:02:00.0";
    };

    storage = {
      minipc = {
        nvme-ssd-0 = "nvme-WD_PC_SN810_SDCPNRY-512G-1006_23302N805496";
        nvme-ssd-1 = "nvme-Netac_NVMe_SSD_256GB_AA20251013256G327033";
      };
      desktop = {
        nvme-ssd-0 = "nvme-TEAM_TM8FP6512G_TPBF2409020100200448";
        sata-ssd-0 = "ata-ZTSSD-S10-240G-TB_1B0607691D0805876831";
      };
      external = {
        usb-hdd-0 = "ata-WDC_WD30PURX-64AKYY0_WD-WX22DB1D35NH";
        usb-hdd-1 = "ata-WDC_WD20NMVW-11EDZS7_WD-WXA1A77H0315";
      };
    };

    radios = {
      zigbee = "usb-1a86_USB_Serial-if00-port0";
      zwave = "usb-Silicon_Labs_CP2102N_USB_to_UART_Bridge_Controller_80edec297b57ed1193f12ef21c62bc44-if00-port0";
    };
  };

  virtualization = {
    vm-network = {
      uuid = "2b7de5db-e0e6-4f81-b5f4-4efc928ee475";
      cpu = 6;
      memory = 2048;
      storage = {
        type = "lvm";
        size = "50G";
      };
      mac = "52:54:00:00:00:00";
    };
    vm-app = {
      uuid = "532ea825-4ca3-46a2-b15d-ba8af70ba733";
      cpu = 12;
      memory = 10240;
      storage = {
        type = "lvm";
        size = "300G";
      };
      mac = "52:54:00:00:00:01";
    };
    vm-monitor = {
      uuid = "26a3e5f9-5c4a-4956-8ee4-b680f507d3cc";
      cpu = 6;
      memory = 6144;
      storage = {
        type = "lvm";
        size = "100G";
      };
      mac = "52:54:00:00:00:02";
    };
    vm-public = {
      uuid = "ec5663c9-bac8-4d69-b120-b2b63a456a67";
      cpu = 4;
      memory = 2048;
      storage = {
        type = "lvm";
        size = "20G";
      };
      mac = "52:54:00:00:00:03";
    };
    vm-cyber = {
      uuid = "008d571b-aa7c-4050-96d8-7185f5ea2a95";
      cpu = 6;
      memory = 6144;
      storage = {
        type = "lvm";
        size = "50G";
      };
      mac = "52:54:00:00:00:04";
    };
  };

  daily-tasks = {
    hypervisor = {
      podman-update = "03:00";
      trivy-scan = "03:10";
      restic-backup = "06:30";
      smartd-test = "02:00";
    };
    pi = {
      podman-update = "03:00";
    };
    vm-network = {
      podman-update = "03:05";
      trivy-scan = "03:15";
      restic-backup = "06:35";
    };
    vm-app = {
      podman-update = "03:10";
      trivy-scan = "03:25";
      restic-backup = "04:00";
      container-db-backup = "03:30";
      nix-build = "05:30";
    };
    vm-monitor = {
      podman-update = "03:30";
      trivy-scan = "03:50";
      restic-backup = "06:45";
      container-db-backup = "03:45";
    };
    vm-public = {
      podman-update = "03:35";
      trivy-scan = "03:50";
    };
  };

  endpoints = {
    oidc-issuer = "${subdomains.vm-app.pocketid}.${domain}";
    private-repo = "${subdomains.vm-app.forgejo}.${domain}";
    vpn-server = "vpn.${domain}";
    ntfy-server = "${subdomains.vm-monitor.ntfy}.${domain}";
    ntfy-topics = {
      prometheus-alerts = "prometheus-alerts";
      harmonia-alerts = "harmonia-alerts";
      gatus-alerts = "gatus-alerts";
      trivy = "trivy-alerts";
    };
  };
}
