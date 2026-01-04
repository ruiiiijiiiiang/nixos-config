{
  selfhost = {
    beszel = {
      hub.enable = true;
      agent.enable = true;
    };
    gatus.enable = true;
    nginx.enable = true;
    prometheus = {
      server.enable = true;
      exporters = {
        nginx.enable = true;
        node.enable = true;
        podman.enable = true;
      };
    };
    wazuh = {
      server.enable = true;
      agent.enable = true;
    };
  };
}
