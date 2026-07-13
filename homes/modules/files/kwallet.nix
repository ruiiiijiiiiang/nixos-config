{ pkgs, ... }:
{
  xdg.dataFile."dbus-1/services/org.freedesktop.secrets.service".text = ''
    [D-BUS Service]
    Name=org.freedesktop.secrets
    Exec=${pkgs.kdePackages.kwallet}/bin/ksecretd
  '';
}
