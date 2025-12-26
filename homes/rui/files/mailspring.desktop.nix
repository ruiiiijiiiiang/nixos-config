{
  # Set up extra flags on Mailspring
  home.file.".local/share/applications/Mailspring.desktop".text = ''
    [Desktop Entry]
    Name=Mailspring
    Comment=The best email app for people and teams at work
    GenericName=Mail Client
    Exec=env ELECTRON_OZONE_PLATFORM_HINT=x11 mailspring --password-store=kwallet6 %U
    Icon=mailspring
    Type=Application
    StartupNotify=true
    StartupWMClass=Mailspring
    Categories=GNOME;GTK;Network;Email;
    Keywords=email;internet;
    MimeType=x-scheme-handler/mailto;x-scheme-handler/mailspring;
    Actions=NewMessage

    [Desktop Action NewMessage]
    Name=New Message
    Exec=env ELECTRON_OZONE_PLATFORM_HINT=x11 mailspring --password-store=kwallet6 mailto:
  '';
}
