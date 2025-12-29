{ consts, ... }:
with consts;
{
  users = {
    users.rui = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "networkmanager"
        "podman"
      ];
      initialPassword = "yoloswag";
      group = "rui";
      home = "/home/rui";
      createHome = true;
    };

    groups.rui = {
      name = "rui";
      members = [ "rui" ];
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
