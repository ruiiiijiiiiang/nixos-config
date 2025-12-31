let
  inherit (import ./consts.nix) addresses ports;
in
{
  locations = {
    "= /oauth2/auth" = {
      proxyPass = "http://${addresses.home.hosts.vm-app}:${toString ports.oauth2}/oauth2/auth";
      proxyWebsockets = true;
      extraConfig = ''
        proxy_set_header Content-Length "";
        proxy_pass_request_body off;
      '';
    };

    "/oauth2/" = {
      proxyPass = "http://${addresses.home.hosts.vm-app}:${toString ports.oauth2}";
      proxyWebsockets = true;
    };
  };
}
