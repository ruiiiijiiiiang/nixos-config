{ consts, pkgs, ... }:
let
  inherit (consts)
    timeZone
    locale
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
      shell = pkgs.fish;
    };

    groups.${username} = {
      gid = oci-uids.user;
      name = username;
      members = [ username ];
    };
  };

  time.timeZone = timeZone;

  i18n.defaultLocale = locale;
  i18n.extraLocaleSettings = {
    LC_ADDRESS = locale;
    LC_IDENTIFICATION = locale;
    LC_MEASUREMENT = locale;
    LC_MONETARY = locale;
    LC_NAME = locale;
    LC_NUMERIC = locale;
    LC_PAPER = locale;
    LC_TELEPHONE = locale;
    LC_TIME = locale;
  };
}
