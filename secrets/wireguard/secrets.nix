let
  inherit (import ../../lib/keys.nix) ssh;
in
{
  "wireguard/server-private-key.age" = {
    publicKeys = ssh.vm-network;
    armor = true;
  };
  "wireguard/framework-preshared-key.age" = {
    publicKeys = ssh.vm-network ++ ssh.framework;
    armor = true;
  };
  "wireguard/framework-private-key.age" = {
    publicKeys = ssh.framework;
    armor = true;
  };
  "wireguard/iphone-16-preshared-key.age" = {
    publicKeys = ssh.vm-network;
    armor = true;
  };
  "wireguard/iphone-17-preshared-key.age" = {
    publicKeys = ssh.vm-network;
    armor = true;
  };
  "wireguard/github-action-preshared-key.age" = {
    publicKeys = ssh.vm-network;
    armor = true;
  };
  "wireguard/proton-private-key.age" = {
    publicKeys = ssh.vm-app;
    armor = true;
  };
}
