{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    wezterm
    python313
    rsync
    vivaldi
    zed-editor
  ];
}
