{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.rui.devops;
in {
  config = mkIf cfg.enable {
    services.k3s = {
      enable = true;
      role = "server";
      token = "yolo-swag";
      extraFlags = toString [
        "--write-kubeconfig-mode 644"
        "--tls-san rui-nixos-vm"
      ];
    };

    networking.firewall.allowedTCPPorts = [ 6443 ];
    networking.firewall.allowedUDPPorts = [ 8472 ];

    environment.systemPackages = with pkgs; [
      k3s
      kubectl
      kubernetes-helm
    ];
  };
}
