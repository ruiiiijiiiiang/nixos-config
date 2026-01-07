{
  selfhost = {
    dns.enable = true;
    dyndns.enable = true;
    nginx.enable = true;

    beszel.agent.enable = true;
    dockhand.agent.enable = true;
    prometheus.exporters = {
      nginx.enable = true;
      node.enable = true;
    };
    scanopy.daemon.enable = true;
    wazuh.agent.enable = true;
  };
}
