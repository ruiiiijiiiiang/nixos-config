{ consts, ... }:
let
  inherit (consts)
    timeZone
    defaultLocale
    username
    home
    oci-uids
    ;
in
{
  users = {
    users.${username} = {
      uid = oci-uids.user;
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      initialPassword = "yoloswag";
      group = username;
      inherit home;
      createHome = true;
    };

    groups.${username} = {
      gid = oci-uids.user;
      name = username;
      members = [ username ];
    };
  };

  time.timeZone = timeZone;

  i18n.defaultLocale = defaultLocale;
  i18n.extraLocaleSettings = {
    LC_ADDRESS = defaultLocale;
    LC_IDENTIFICATION = defaultLocale;
    LC_MEASUREMENT = defaultLocale;
    LC_MONETARY = defaultLocale;
    LC_NAME = defaultLocale;
    LC_NUMERIC = defaultLocale;
    LC_PAPER = defaultLocale;
    LC_TELEPHONE = defaultLocale;
    LC_TIME = defaultLocale;
  };
}
