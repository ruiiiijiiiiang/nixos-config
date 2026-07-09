{
  consts,
  lib,
  pkgs,
  ...
}:
let
  inherit (consts)
    addresses
    subdomains
    oci-uids
    ;
in
rec {
  dailyTaskToCron =
    time:
    let
      inherit (lib)
        splitString
        toString
        toIntBase10
        elemAt
        ;
      parts = splitString ":" time;
      hour = toString (toIntBase10 (elemAt parts 0));
      minute = toString (toIntBase10 (elemAt parts 1));
    in
    "${minute} ${hour} * * *";

  dailyTaskToSystemd = time: "*-*-* ${time}:00";

  ensureFile =
    {
      source,
      destination,
      user ? "root",
      group ? "root",
      mode ? "640",
    }:
    /* bash */ ''
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
        bytestash = config.custom.services.apps.development.bytestash.enable;
        changedetection = config.custom.services.apps.tools.changedetection.enable;
        cockpit = config.custom.services.observability.cockpit.enable;
        dawarich = config.custom.services.apps.location.dawarich.enable;
        dockhand = config.custom.services.observability.dockhand.server.enable;
        forgejo = config.custom.services.apps.development.forgejo.enable;
        gatus = config.custom.services.observability.gatus.enable;
        grafana = config.custom.services.observability.grafana.enable;
        harmonia = config.custom.services.infra.harmonia.enable;
        homeassistant = config.custom.services.apps.tools.homeassistant.enable;
        homepage = config.custom.services.apps.web.homepage.enable;
        immich = config.custom.services.apps.media.immich.enable;
        jellyfin = config.custom.services.apps.media.jellyfin.enable;
        karakeep = config.custom.services.apps.tools.karakeep.enable;
        krawl = config.custom.services.security.krawl.enable;
        librechat = config.custom.services.apps.ai.librechat.enable;
        magicmirror = config.custom.services.apps.web.magicmirror.enable;
        mealie = config.custom.services.apps.tools.mealie.enable;
        memos = config.custom.services.apps.office.memos.enable;
        microbin = config.custom.services.apps.tools.microbin.enable;
        myspeed = config.custom.services.observability.myspeed.enable;
        ntfy = config.custom.services.observability.ntfy.enable;
        netalertx = config.custom.services.observability.netalertx.enable;
        nextcloud = config.custom.services.apps.office.nextcloud.enable;
        onlyoffice = config.custom.services.apps.office.opencloud.enable;
        opencloud = config.custom.services.apps.office.opencloud.enable;
        openwebui = config.custom.services.apps.ai.llm.enable;
        paperless = config.custom.services.apps.office.paperless.enable;
        ovumcy = config.custom.services.apps.tools.ovumcy.enable;
        pricebuddy = config.custom.services.apps.tools.pricebuddy.enable;
        pihole = config.custom.services.networking.dns.enable;
        pocketid = config.custom.services.apps.auth.pocketid.enable;
        portainer = config.custom.services.observability.portainer.enable;
        prometheus = config.custom.services.observability.prometheus.server.enable;
        public = config.custom.services.apps.web.website.enable;
        qbittorrent = config.custom.services.networking.torrent.enable;
        reitti = config.custom.services.apps.location.reitti.enable;
        scanopy = config.custom.services.observability.scanopy.server.enable;
        searxng = config.custom.services.apps.web.searxng.enable;
        stirlingpdf = config.custom.services.apps.office.stirlingpdf.enable;
        syncthing = config.custom.services.apps.tools.syncthing.enable;
        termix = config.custom.services.observability.termix.enable;
        vaultwarden = config.custom.services.apps.auth.vaultwarden.enable;
        wazuh = config.custom.services.security.wazuh.server.enable;
        yourls = config.custom.services.apps.web.yourls.enable;
        zeroclaw = config.custom.services.apps.ai.zeroclaw.enable;
        zwave = config.custom.services.apps.tools.homeassistant.enable;
      };
      subdomainSet = subdomains.${config.networking.hostName} or { };
    in
    filterAttrs (key: value: serviceEnabled.${key} or false) subdomainSet;

  resolveHostArgs =
    args:
    let
      argsSet = if builtins.isAttrs args then args else { hostName = args; };
      inherit (argsSet) hostName;
      network = argsSet.network or null;
      isV6 = argsSet.isV6 or false;
      resolvedHostName = if isV6 && !lib.hasSuffix "-v6" hostName then "${hostName}-v6" else hostName;
    in
    {
      hostName = resolvedHostName;
      inherit network isV6;
    };

  getHostNetwork =
    args:
    let
      resolved = resolveHostArgs args;
      baseHostName =
        if lib.hasSuffix "-v6" resolved.hostName then
          lib.removeSuffix "-v6" resolved.hostName
        else
          resolved.hostName;
    in
    lib.findFirst (net: lib.hasAttrByPath [ net "hosts" baseHostName ] addresses) null [
      "infra"
      "home"
      "dmz"
    ];

  getHostAddress =
    args:
    let
      resolved = resolveHostArgs args;
      net = if resolved.network != null then resolved.network else getHostNetwork resolved.hostName;
    in
    if net != null && lib.hasAttrByPath [ net "hosts" resolved.hostName ] addresses then
      addresses.${net}.hosts.${resolved.hostName}
    else if (builtins.isAttrs args && args ? network) then
      builtins.throw "No address found for host `${resolved.hostName}` in addresses.${args.network}.hosts"
    else
      builtins.throw "No address found for host `${resolved.hostName}` in any network (infra, home, dmz)";

  getGatewayAddress =
    args:
    let
      resolved = resolveHostArgs args;
      net = if resolved.network != null then resolved.network else getHostNetwork resolved.hostName;
      gatewayHost =
        if resolved.isV6 || lib.hasSuffix "-v6" resolved.hostName then "vm-network-v6" else "vm-network";
    in
    if net != null then
      addresses.${net}.hosts.${gatewayHost}
    else
      builtins.throw "No network found for host `${resolved.hostName}` to determine gateway";

  getHostSubnet =
    args:
    let
      resolved = resolveHostArgs args;
      net = getHostNetwork resolved;
    in
    if net != null then
      addresses.${net}.${if resolved.isV6 then "network-v6" else "network"}
    else
      builtins.throw "No network found for host `${resolved.hostName}` to determine subnet";

  mkNotifyService =
    {
      timeout ? 300,
    }:
    {
      serviceConfig = {
        Type = "notify";
        NotifyAccess = "all";
        TimeoutStartSec = lib.mkForce (toString timeout);
      };
    };

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

  mkVirtualHost =
    {
      fqdn,
      port,
      extraConfig ? "",
    }:
    {
      useACMEHost = fqdn;
      forceSSL = true;
      http3 = true;
      quic = true;
      locations."/" = {
        proxyPass = "http://${addresses.localhost}:${toString port}";
        proxyWebsockets = true;
        inherit extraConfig;
      };
    };

  parsePciAddress =
    addrStr:
    let
      inherit (lib) match fromHexString elemAt;
      parts = match "([0-9a-fA-F]+):([0-9a-fA-F]+):([0-9a-fA-F]+)\\.([0-9a-fA-F]+)" addrStr;
    in
    if parts == null then
      builtins.throw "Invalid PCI address: ${addrStr}. Expected format DDDD:BB:SS.F"
    else
      {
        domain = fromHexString (elemAt parts 0);
        bus = fromHexString (elemAt parts 1);
        slot = fromHexString (elemAt parts 2);
        function = fromHexString (elemAt parts 3);
      };

  linkConfig =
    {
      dotfilesRoot,
      name,
      paths,
    }:
    let
      inherit (lib)
        escapeShellArg
        listToAttrs
        isString
        hasPrefix
        ;
      dotfilesOutOfStore = !(hasPrefix "/nix/store" (toString dotfilesRoot));
      mkOutOfStoreSymlink =
        path:
        let
          pathStr = toString path;
          name = baseNameOf pathStr;
        in
        pkgs.runCommandLocal name { } "ln -s ${escapeShellArg pathStr} $out";
    in
    listToAttrs (
      map (
        item:
        let
          isSimple = isString item;
          targetPath = if isSimple then item else item.target;
          sourceSuffix = if isSimple then item else item.src;
        in
        {
          name = targetPath;
          value.source =
            if dotfilesOutOfStore then
              mkOutOfStoreSymlink "${toString dotfilesRoot}/${name}/${sourceSuffix}"
            else
              "${dotfilesRoot}/${name}/${sourceSuffix}";
        }
      ) paths
    );

  adjustTime =
    offset: time:
    let
      sign = builtins.substring 0 1 offset;
      rest = builtins.substring 1 (builtins.stringLength offset - 1) offset;
      len = builtins.stringLength rest;
      unit = builtins.substring (len - 1) 1 rest;
      amountStr = builtins.substring 0 (len - 1) rest;
      validSign =
        if
          builtins.elem sign [
            "+"
            "-"
          ]
        then
          true
        else
          throw "adjustTime: offset must start with '+' or '-', got '${sign}' in '${offset}'";
      validUnit =
        if
          builtins.elem unit [
            "m"
            "h"
          ]
        then
          true
        else
          throw "adjustTime: offset must end with 'm' (minutes) or 'h' (hours), got '${unit}' in '${offset}'";
      stripZero =
        str:
        if builtins.substring 0 1 str == "0" && builtins.stringLength str > 1 then
          builtins.substring 1 (builtins.stringLength str - 1) str
        else
          str;
      toInt = str: (builtins.fromTOML "x = ${stripZero str}").x;
      amount = toInt amountStr;
      hour = toInt (builtins.substring 0 2 time);
      minute = toInt (builtins.substring 3 2 time);
      offsetMinutes = if unit == "h" then amount * 60 else amount;
      totalMinutes = hour * 60 + minute;
      adjustedMinutes =
        if sign == "+" then totalMinutes + offsetMinutes else totalMinutes - offsetMinutes;
      mod = a: b: a - (b * (a / b));
      moddedMinutes =
        let
          m = adjustedMinutes;
          mPositive = if m < 0 then m + (1440 * ((-m / 1440) + 1)) else m;
        in
        mod mPositive 1440;
      finalHour = moddedMinutes / 60;
      finalMinute = mod moddedMinutes 60;
      pad = n: if n < 10 then "0" + builtins.toString n else builtins.toString n;
    in
    assert validSign && validUnit;
    "${pad finalHour}:${pad finalMinute}";
}
