{
  selfhost = {
    dns.enable = true;
    dyndns.enable = true;
    monit.enable = true;
    nginx.enable = true;

    beszel.agent.enable = true;
    prometheus.exporters = {
      nginx.enable = true;
      node.enable = true;
    };
    wazuh.agent.enable = true;
  };
}
