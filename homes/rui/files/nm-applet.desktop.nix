{ ... }:

{
  # Hide nm-applet tray icon
  home.file.".config/autostart/nm-applet.desktop".text = ''
    [Desktop Entry]
    Name=NetworkManager Applet
    Comment=Manage your network connections
    Icon=nm-device-wireless
    Exec=nm-applet
    Terminal=false
    Type=Application
    NoDisplay=true
    NotShowIn=KDE;GNOME;
    X-GNOME-UsesNotifications=true
    Hidden=true
  '';
}
