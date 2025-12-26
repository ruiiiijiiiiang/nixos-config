{
  # Hide xwayland bridge
  home.file.".config/autostart/org.kde.xwaylandvideobridge.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Wayland to X recording bridge (masked)
    Hidden=true
  '';
}
