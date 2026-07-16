{ self, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    let
      inherit (pkgs) lib;
      consts = import ../lib/consts.nix;

      netColors = {
        home = {
          fill = "#253046";
          stroke = "#8CAAEE";
        };
        infra = {
          fill = "#322644";
          stroke = "#CA9EE6";
        };
        dmz = {
          fill = "#3d252a";
          stroke = "#E78284";
        };
        wg = {
          fill = "#233227";
          stroke = "#A6D189";
        };
      };

      serviceIcons = {
        immich = "immich";
        jellyfin = "jellyfin";
        bytestash = "bytestash";
        forgejo = "forgejo";
        sonarr = "sonarr";
        radarr = "radarr";
        lidarr = "lidarr";
        prowlarr = "prowlarr";
        bazarr = "bazarr";
        qbittorrent = "qbittorrent";
        opencloud = "open-cloud";
        paperless = "paperless";
        memos = "memos";
        pocketid = "pocket-id";
        vaultwarden = "vaultwarden";
        harmonia = "https://avatars.githubusercontent.com/u/33221035";
        homeassistant = "home-assistant";
        microbin = "microbin";
        karakeep = "karakeep";
        librechat = "librechat";
        openwebui = "open-webui";
        reitti = "https://cdn.jsdelivr.net/gh/selfhst/icons@main/png/reitti.png";
        ovumcy = "https://raw.githubusercontent.com/ovumcy/ovumcy-web/refs/heads/main/web/static/brand/ovumcy-icon-dark.svg";
        pricebuddy = "price-buddy";
        changedetection = "changedetection";
        mealie = "mealie";
        netalertx = "netalertx";
        pihole = "pi-hole";
        cockpit = "cockpit";
        termix = "termix";
        gatus = "gatus";
        dockhand = "https://cdn.jsdelivr.net/gh/selfhst/icons@main/png/dockhand.png";
        beszel = "beszel";
        prometheus = "prometheus";
        grafana = "grafana";
        ntfy = "ntfy";
        syncthing = "syncthing";
        zwave = "z-wave-js-ui";
        wazuh = "wazuh";
        krawl = "https://raw.githubusercontent.com/BlessedRebuS/Krawl/refs/heads/main/img/krawl-svg.svg";
        bentopdf = "bentopdf";
        atuin = "atuin";
        stirlingpdf = "stirling-pdf";
        portainer = "portainer";
        myspeed = "myspeed";
        scanopy = "https://raw.githubusercontent.com/scanopy/scanopy/main/media/logo.png";
        yourls = "yourls";
        onlyoffice = "onlyoffice";
        nextcloud = "nextcloud";
        website = "https://raw.githubusercontent.com/ruiiiijiiiiang/website/refs/heads/main/assets/favicon.ico";
        searxng = "searxng";
        zeroclaw = "https://raw.githubusercontent.com/zeroclaw-labs/zeroclaw/master/web/public/logo.png";
        niri = "https://raw.githubusercontent.com/wiki/niri-wm/niri/logo/niri-logo.svg";
        noctalia = "https://raw.githubusercontent.com/noctalia-dev/noctalia/main/assets/noctalia.svg";
        wezterm = "https://raw.githubusercontent.com/wez/wezterm/main/assets/icon/terminal.png";
        fish = "https://user-images.githubusercontent.com/920838/47693595-844df600-dbb7-11e8-9cfd-bdb8dbcfa233.gif";
        lxqt = "https://raw.githubusercontent.com/lxqt/wiki/master/docs/lxqt.wiki/_assets/lxqt.svg";
        nmap = "https://nmap.org/images/sitelogo.png";
        burpsuite = "https://raw.githubusercontent.com/simple-icons/simple-icons/develop/icons/burpsuite.svg";
        metasploit = "https://raw.githubusercontent.com/simple-icons/simple-icons/develop/icons/metasploit.svg";
        wireshark = "https://raw.githubusercontent.com/simple-icons/simple-icons/develop/icons/wireshark.svg";
      };

      getIconUrl =
        svc:
        let
          iconVal = serviceIcons.${svc} or svc;
          isUrl = lib.hasPrefix "http://" iconVal || lib.hasPrefix "https://" iconVal;
        in
        if isUrl then
          iconVal
        else
          "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/${iconVal}.png";

      # Helper to resolve enabled services
      getEnabledServices =
        config:
        let
          helpers = import ../lib/helpers.nix {
            inherit consts lib pkgs;
          };
        in
        helpers.getEnabledServices { inherit config; };

      # Collect info for all hosts
      hostsInfo = lib.mapAttrs (
        hostName: hostObj:
        let
          inherit (hostObj) config;
          guestVms = config.custom.services.infra.hypervisor.guestVms or [ ];
          enabledServices = getEnabledServices config;
        in
        {
          inherit guestVms;
          services =
            builtins.attrNames enabledServices
            ++ (
              if
                lib.elem hostName [
                  "framework"
                  "desktop"
                ]
              then
                [
                  "niri"
                  "noctalia"
                  "wezterm"
                  "fish"
                ]
              else if hostName == "vm-cyber" then
                [
                  "lxqt"
                  "nmap"
                  "burpsuite"
                  "metasploit"
                  "wireshark"
                ]
              else
                [ ]
            );
          networks =
            map
              (net: {
                name = net;
                ip = consts.addresses.${net}.hosts.${hostName};
              })
              (
                lib.filter (net: builtins.hasAttr hostName (consts.addresses.${net}.hosts or { })) (
                  builtins.attrNames consts.addresses
                )
              );
        }
      ) self.nixosConfigurations;

      # Identify VMs
      allVms = lib.foldl' (acc: hostName: acc ++ hostsInfo.${hostName}.guestVms) [ ] (
        builtins.attrNames hostsInfo
      );

      # Helper: render flat services list
      renderServices =
        indent: services:
        lib.concatMapStringsSep "\n" (
          svc:
          let
            label =
              if svc == "fish" then
                "fish shell"
              else if svc == "burpsuite" then
                "burp suite"
              else
                svc;
          in
          ''
            ${indent}${svc}: "${label}" {
              class: service
              icon: "${getIconUrl svc}"
            }
          ''
        ) services;

      # 1. Define Network clouds
      networksD2 = ''
        # Network Segments
        ${lib.concatMapStringsSep "\n\n"
          (
            netName:
            let
              netInfo = netColors.${netName};
              cidr = consts.addresses.${netName}.network;
            in
            ''
              ${netName}: "${lib.toUpper netName} VLAN\n${cidr}" {
                shape: cloud
                style.fill: "${netInfo.fill}"
                style.stroke: "${netInfo.stroke}"
                style.font-color: "#c6d0f5"
              }''
          )
          [
            "home"
            "infra"
            "dmz"
            "wg"
          ]
        }
      '';

      # 2. Define Hosts D2
      renderHost =
        hostName: hostInfo:
        let
          isVm = lib.elem hostName allVms;
          label =
            if hostName == "framework" then
              "Framework Laptop\\n(Workstation)"
            else if hostName == "desktop" then
              "Desktop\\n(Workstation)"
            else if hostName == "pi" then
              "Raspberry Pi 4\\n(IoT)"
            else if hostName == "hypervisor" then
              "Mini PC\\n(Hypervisor)"
            else
              hostName;
        in
        if isVm then
          "" # Rendered inside hypervisor
        else
          ''
            ${hostName}: "${label}" {
              class: physical
              ${if hostName == "hypervisor" then "direction: right" else "grid-columns: 1"}
              ${lib.optionalString (hostName == "hypervisor") ''
                mgmt: "Host Management" {
                  style.fill: "#303446"
                  style.stroke: "#414559"
                  style.font-color: "#c6d0f5"
                  grid-columns: 1
                  cockpit: "Cockpit" {
                    class: service
                    icon: "${getIconUrl "cockpit"}"
                  }
                }

                ${lib.concatMapStringsSep "\n\n                " (vmName: ''
                  ${vmName}: "vm-${lib.removePrefix "vm-" vmName}\n(${
                    if vmName == "vm-network" then
                      "Gateway Router"
                    else if vmName == "vm-app" then
                      "Application Server"
                    else if vmName == "vm-monitor" then
                      "Monitoring & Security"
                    else if vmName == "vm-public" then
                      "Public Services"
                    else if vmName == "vm-cyber" then
                      "Security Lab"
                    else
                      "Virtual Machine"
                  })" {
                    class: vm
                    grid-rows: 4
                    grid-columns: 3
                    ${renderServices "                    " hostsInfo.${vmName}.services}
                  }'') hostInfo.guestVms}
              ''}
              ${lib.optionalString (hostName != "hypervisor" && hostInfo.services != [ ]) (
                renderServices "  " hostInfo.services
              )}
            }
          '';

      hostsD2 = ''
        # Physical and Virtual Infrastructure
        ${lib.concatStringsSep "\n" (lib.mapAttrsToList renderHost hostsInfo)}
      '';

      # 3. Connections D2
      renderConnections =
        hostName: hostInfo:
        let
          isVm = lib.elem hostName allVms;
          d2Path =
            if hostName == "hypervisor" then
              "hypervisor.mgmt"
            else if isVm then
              "hypervisor.${hostName}"
            else
              hostName;
        in
        lib.concatMapStringsSep "\n" (
          net:
          if lib.hasAttr net.name netColors then
            ''
              ${net.name} -- ${d2Path}: "${net.ip}" {
                style.stroke: "${netColors.${net.name}.stroke}"
                style.stroke-width: 2
                style.font-color: "#c6d0f5"
              }
            ''
          else
            ""
        ) hostInfo.networks;

      connectionsD2 = ''
        # Network Interconnections
        ${lib.concatStringsSep "\n" (lib.mapAttrsToList renderConnections hostsInfo)}
      '';

      # Full D2 file content
      d2Content = ''
        # D2 Network Topology Diagram
        # Auto-generated from NixOS configuration. DO NOT EDIT.

        direction: down

        vars: {
          d2-config: {
            theme-id: 200
          }
        }

        style: {
          fill: "#232634"
        }

        # Global Styles
        classes: {
          physical: {
            style: {
              fill: "#303446"
              stroke: "#51576D"
              stroke-width: 3
              font-color: "#c6d0f5"
            }
          }
          vm: {
            style: {
              fill: "#292C3C"
              stroke: "#414559"
              stroke-width: 2
              font-color: "#a5adce"
            }
          }
          network: {
            style: {
              stroke-width: 2
              stroke-dash: 5
            }
          }
          service: {
            width: 120
            height: 100
            style: {
              fill: "#414559"
              stroke: "#51576D"
              stroke-width: 2
              font-color: "#c6d0f5"
            }
          }
        }

        ${networksD2}

        ${hostsD2}

        ${connectionsD2}
      '';
    in
    {
      packages.generate-topology = pkgs.writeShellApplication {
        name = "generate-topology";
        runtimeInputs = [
          pkgs.d2
          pkgs.inkscape
        ];
        text = ''
          echo "Generating topology/topology.d2..."
          cat << 'EOF' > topology/topology.d2
          ${d2Content}
          EOF

          echo "Rendering topology/topology.svg..."
          d2 --layout=elk topology/topology.d2 topology/topology.svg

          echo "Rendering topology/topology.png..."
          inkscape topology/topology.svg -o topology/topology.png

          echo "Done! Diagram files generated: topology/topology.d2, topology/topology.svg, topology/topology.png"
        '';
      };

      apps.generate-topology = {
        type = "app";
        program = "${self.packages.${system}.generate-topology}/bin/generate-topology";
      };
    };
}
