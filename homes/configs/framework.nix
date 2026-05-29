{ consts, ... }:
let
  inherit (consts) ports endpoints;
in
{
  imports = [
    ../modules/files
  ];

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "forgejo" = {
        hostname = endpoints.private-repo;
        user = "git";
        port = ports.forgejo.ssh;
      };
      "*" = {
        identityFile = "~/.ssh/id_ed25519";
      };
    };
  };

  custom.home = {
    dotfiles = {
      enable = true;
      role = "workstation";
      host = "framework";
    };
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "application/pdf" = "okularApplication_pdf.desktop";
      "application/epub+zip" = "okularApplication_epub.desktop";
      "application/x-cbz" = "okularApplication_comicbook.desktop";
      "application/x-cbr" = "okularApplication_comicbook.desktop";

      "application/x-7z-compressed" = "org.kde.ark.desktop";
      "application/x-rar" = "org.kde.ark.desktop";
      "application/vnd.rar" = "org.kde.ark.desktop";
      "application/x-tar" = "org.kde.ark.desktop";
      "application/zip" = "org.kde.ark.desktop";

      "image/gif" = "org.kde.gwenview.desktop";
      "image/jpeg" = "org.kde.gwenview.desktop";
      "image/png" = "org.kde.gwenview.desktop";
      "image/webp" = "org.kde.gwenview.desktop";
      "image/svg+xml" = "org.kde.gwenview.desktop";

      "application/json" = "dev.zed.Zed.desktop";
      "application/toml" = "dev.zed.Zed.desktop";
      "application/xml" = "dev.zed.Zed.desktop";
      "text/csv" = "dev.zed.Zed.desktop";
      "text/markdown" = "dev.zed.Zed.desktop";
      "text/plain" = "dev.zed.Zed.desktop";
      "text/yaml" = "dev.zed.Zed.desktop";

      "text/html" = "vivaldi-stable.desktop";
      "x-scheme-handler/http" = "vivaldi-stable.desktop";
      "x-scheme-handler/https" = "vivaldi-stable.desktop";
      "x-scheme-handler/about" = "vivaldi-stable.desktop";
      "x-scheme-handler/unknown" = "vivaldi-stable.desktop";

      "x-scheme-handler/tg" = "org.telegram.desktop.desktop";
      "x-scheme-handler/tonsite" = "org.telegram.desktop.desktop";
    };
  };
}
