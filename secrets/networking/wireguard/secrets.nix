let
  inherit (import ../../../lib/keys.nix) ssh;
in
{
  "networking/wireguard/server-private-key.age" = {
    publicKeys = ssh.vm-network;
    armor = true;
  };
  "networking/wireguard/framework-preshared-key.age" = {
    publicKeys = ssh.vm-network ++ ssh.framework;
    armor = true;
  };
  "networking/wireguard/framework-private-key.age" = {
    publicKeys = ssh.framework;
    armor = true;
  };
  "networking/wireguard/pixel-7-preshared-key.age" = {
    publicKeys = ssh.vm-network;
    armor = true;
  };
  "networking/wireguard/iphone-17-preshared-key.age" = {
    publicKeys = ssh.vm-network;
    armor = true;
  };
  "networking/wireguard/github-action-preshared-key.age" = {
    publicKeys = ssh.vm-network;
    armor = true;
  };
  "networking/wireguard/proton-private-key.age" = {
    publicKeys = ssh.vm-app;
    armor = true;
  };
}
