{
  selfhost = {
    dns.enable = true;
    homeassistant.enable = true;
    monit.enable = true;
    nginx.enable = true;

    beszel.agent.enable = true;
    prometheus.exporters = {
      nginx.enable = true;
      node.enable = true;
      podman.enable = true;
    };
  };
}
