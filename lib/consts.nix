{
  timeZone = "America/Chicago";
  defaultLocale = "en_US.UTF-8";

  # please don't DDOS :)
  domains = {
    home = "ruijiang.me";
    tplink = "ruijiang.tplinkdns.com";
  };

  addresses = {
    localhost = "127.0.0.1";
    home = {
      network = "192.168.68.0/24";
      hosts = {
        arch = "192.168.68.65";
        pi = {
          ethernet = "192.168.68.80";
          wifi = "192.168.68.88";
        };
        nixos = "192.168.68.85";
        desktop = {
          ethernet = "192.168.68.81";
          wifi = "192.168.68.76";
        };
      };
    };
    vpn = {
      network = "10.0.0.0/8";
      hosts = {
        iphone = "10.5.5.2";
        nixos = "10.5.5.4";
      };
    };
  };

  ports = {
    monit = 2812;
    unbound = 5335;
    pihole = 8008;
    bentopdf = 8080;
    seafile = {
      web = 8000;
      fileServer = 8082;
    };
    microbin = 8088;
    zwave = {
      server = 8091;
      websocket = 3000;
    };
    homeassistant = 8123;
    vaultwarden = {
      server = 8222;
      websocket = 3012;
    };
    syncthing = 8384;
    atuin = 8888;
    website = 8964;
    wireguard = 51820;
  };
}
