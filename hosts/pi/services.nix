{
  selfhost = {
    dns.enable = true;
    homeassistant.enable = true;
    nginx.enable = true;

    beszel.agent.enable = true;
    dockhand.agent.enable = true;
    prometheus.exporters = {
      nginx.enable = true;
      node.enable = true;
      podman.enable = true;
    };
  };
}
