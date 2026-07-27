{
  home.file.".local/share/applications/goofcord.desktop".text = ''
    [Desktop Entry]
    Categories=Network;InstantMessaging;Chat
    Comment=Highly configurable and privacy-focused Discord client
    Exec=goofcord --password-store=kwallet6 %U
    GenericName=Internet Messenger
    Icon=goofcord
    Keywords=discord;vencord;electron;chat
    Name=GoofCord
    StartupWMClass=GoofCord
    Terminal=false
    Type=Application
    Version=1.5
  '';
}
