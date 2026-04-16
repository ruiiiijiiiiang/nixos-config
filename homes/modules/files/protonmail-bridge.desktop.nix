{
  home.file.".config/autostart/protonmail-bridge.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Proton Mail Bridge
    Exec=protonmail-bridge --backend kwallet
    Icon=protonmail-bridge
    Categories=Network;Email;
    X-GNOME-Autostart-enabled=true
    NotShowIn=KDE;
  '';

  home.file.".local/share/applications/protonmail-bridge.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Proton Mail Bridge
    Exec=protonmail-bridge --backend kwallet
    Icon=protonmail-bridge
    Categories=Network;Email;
  '';
}
