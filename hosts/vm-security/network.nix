let
  inherit (import ../../../lib/keys.nix) ssh;
in
{
  networking = {
    hostName = "vm-security";
  };

  users.users.rui.openssh.authorizedKeys.keys = ssh.rui-arch ++ ssh.framework;
}
