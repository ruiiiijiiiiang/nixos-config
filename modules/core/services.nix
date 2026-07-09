{
  config,
  inputs,
  keys,
  secrets,
  secretsDir,
  lib,
  ...
}:
{
  imports = [
    inputs.agenix.nixosModules.default
  ];
  age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  assertions =
    let
      hostKeys = keys.ssh.${config.networking.hostName} or [ ];
      activeSecrets = lib.filterAttrs (name: val: val.file != null) config.age.secrets;
    in
    lib.mapAttrsToList (
      name: secretVal:
      let
        secretsDirPrefix = (toString secretsDir) + "/";
        secretRelativePath = lib.removePrefix secretsDirPrefix (toString secretVal.file);
        authorizedKeys = secrets.${secretRelativePath}.publicKeys or [ ];
        isAuthorized = lib.any (hostKey: lib.elem hostKey authorizedKeys) hostKeys;
      in
      {
        assertion = isAuthorized;
        message = "The host '${config.networking.hostName}' requires agenix secret '${name}' (${secretRelativePath}), but the host's SSH public key is not configured in secrets/secrets.nix.";
      }
    ) activeSecrets;

  services = {
    xserver.xkb = {
      layout = "us";
      options = "caps:escape";
    };

    ntp.enable = false;
    chrony.enable = true;
  };
}
