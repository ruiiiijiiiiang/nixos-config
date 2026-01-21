{
  lib,
  consts,
  pkgs,
  ...
}:
let
  inherit (consts)
    addresses
    macs
    domains
    subdomains
    oci-uids
    ;
in
rec {
  mkVirtualHost =
    {
      fqdn,
      port,
      extraConfig ? "",
    }:
    {
      useACMEHost = fqdn;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://${addresses.localhost}:${toString port}";
        proxyWebsockets = true;
        inherit extraConfig;
      };
    };

  getReservations =
    let
      inherit (addresses.home) hosts;
    in
    builtins.map (hostname: {
      hw-address = macs.${hostname};
      ip-address = hosts.${hostname};
      inherit hostname;
    }) (builtins.filter (hostname: builtins.hasAttr hostname hosts) (builtins.attrNames macs));

  ensureFile =
    {
      source,
      destination,
      user ? "root",
      group ? "root",
      mode ? "640",
    }:
    ''
      mkdir -p "$(dirname "${destination}")"

      if [ ! -f "${destination}" ] || ! ${pkgs.diffutils}/bin/cmp -s "${source}" "${destination}"; then
        echo "Updating content for ${destination}..."
        cat "${source}" > "${destination}"
      else
        echo "${destination} already exists. Skipping initialization."
      fi

      chown ${user}:${group} "${destination}"
      chmod ${mode} "${destination}"
    '';

  mkHostFqdns =
    hostName:
    let
      hostSubdomainsSet = subdomains.${hostName} or { };
      hostSubdomainList = lib.attrValues hostSubdomainsSet;
    in
    map (sub: "${sub}.${domains.home}") hostSubdomainList;

  mkExtraHosts =
    let
      inherit (lib) concatStringsSep mapAttrsToList;
      makeHostEntry = hostName: ip: "${ip} ${hostName}";
    in
    concatStringsSep "\n" (mapAttrsToList makeHostEntry addresses.home.hosts);

  mkFullExtraHosts =
    let
      inherit (lib) concatStringsSep mapAttrsToList filter;
      makeFullHostEntry =
        hostName: ip:
        let
          fqdns = mkHostFqdns hostName;
        in
        if fqdns == [ ] then "" else "${ip} ${concatStringsSep " " fqdns}";
    in
    concatStringsSep "\n" (filter (s: s != "") (mapAttrsToList makeFullHostEntry addresses.home.hosts));

  getEnabledServices =
    { config }:
    let
      inherit (lib) filterAttrs;
      serviceEnabled = {
        lidarr = config.custom.services.apps.tools.arr.enable;
        radarr = config.custom.services.apps.tools.arr.enable;
        sonarr = config.custom.services.apps.tools.arr.enable;
        prowlarr = config.custom.services.apps.tools.arr.enable;
        bazarr = config.custom.services.apps.tools.arr.enable;
        atuin = config.custom.services.apps.tools.atuin.enable;
        beszel = config.custom.services.observability.beszel.hub.enable;
        bentopdf = config.custom.services.apps.office.bentopdf.enable;
        dawarich = config.custom.services.apps.tools.dawarich.enable;
        dockhand = config.custom.services.observability.dockhand.server.enable;
        evebox = config.custom.services.networking.suricata.enable;
        gatus = config.custom.services.observability.gatus.enable;
        grafana = config.custom.services.observability.prometheus.server.enable;
        homeassistant = config.custom.services.apps.tools.homeassistant.enable;
        homepage = config.custom.services.apps.web.homepage.enable;
        immich = config.custom.services.apps.media.immich.enable;
        jellyfin = config.custom.services.apps.media.jellyfin.enable;
        karakeep = config.custom.services.apps.tools.karakeep.enable;
        memos = config.custom.services.apps.office.memos.enable;
        microbin = config.custom.services.apps.tools.microbin.enable;
        myspeed = config.custom.services.observability.myspeed.enable;
        nextcloud = config.custom.services.apps.office.nextcloud.enable;
        onlyoffice = config.custom.services.apps.office.opencloud.enable;
        opencloud = config.custom.services.apps.office.opencloud.enable;
        paperless = config.custom.services.apps.office.paperless.enable;
        pihole = config.custom.services.networking.dns.enable;
        pocketid = config.custom.services.apps.security.pocketid.enable;
        portainer = config.custom.services.apps.tools.portainer.enable;
        prometheus = config.custom.services.observability.prometheus.server.enable;
        public = config.custom.services.apps.web.website.enable;
        qbittorrent = config.custom.services.networking.torrent.enable;
        reitti = config.custom.services.apps.tools.reitti.enable;
        scanopy = config.custom.services.observability.scanopy.server.enable;
        stirlingpdf = config.custom.services.apps.office.stirlingpdf.enable;
        syncthing = config.custom.services.apps.tools.syncthing.enable;
        vaultwarden = config.custom.services.apps.security.vaultwarden.enable;
        wazuh = config.custom.services.observability.wazuh.server.enable;
        yourls = config.custom.services.apps.tools.yourls.enable;
        zwave = config.custom.services.apps.tools.homeassistant.enable;
      };
      subdomainSet = subdomains.${config.networking.hostName} or { };
    in
    filterAttrs (key: value: serviceEnabled.${key} or false) subdomainSet;

  getEnabledSubdomains =
    { config }:
    let
      inherit (lib) unique attrValues;
    in
    unique (
      attrValues (getEnabledServices {
        inherit config;
      })
    );

  mkGatusEndpoints =
    { inputs, hostName }:
    let
      inherit (inputs.self.nixosConfigurations.${hostName}) config;
      enabledServices = getEnabledServices { inherit config; };
    in
    lib.mapAttrsToList (service: subdomain: {
      name = service;
      url = "https://${subdomain}.${domains.home}";
      group = hostName;
      interval = "1m";
      conditions = [ "[STATUS] == 200" ];
    }) enabledServices;

  mkOpenPortRule = port: ''
    ip saddr ${addresses.home.network} tcp dport ${toString port} accept
  '';

  mkOciUser = app: {
    groups.${app} = {
      gid = oci-uids.${app};
    };
    users.${app} = {
      uid = oci-uids.${app};
      group = "${app}";
      isSystemUser = true;
    };
  };
}
