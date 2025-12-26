{
  selfhost = {
    beszel = {
      hub.enable = true;
      agent.enable = true;
    };
    monit.enable = true;
    nginx.enable = true;
    wazuh = {
      server.enable = true;
      agent.enable = true;
    };
  };
}
