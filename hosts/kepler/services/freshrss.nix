{ config, ... }:
{
  k.monitoring = {
    httpEndpoints = [
      {
        name = "freshrss";
        url = "https://rss.kilko.de";
      }
    ];
    systemdServices = [ "freshrss" ];
  };

  services.freshrss = {
    enable = true;

    # baseUrl = "http://localhost:${toString config.k.ports.freshrss_http}";
    baseUrl = "https://rss.kilko.de";

    database = {
      type = "pgsql";
      host = "/run/postgresql";
      port = null; # Use default PostgreSQL port
      user = "freshrss";
      name = "freshrss";
    };

    defaultUser = "admin";
    passwordFile = config.sops.secrets."freshrss/admin_password".path;
    # Use nginx and let the module configure the vhost; we'll override the listen port below.
    webserver = "nginx";
    virtualHost = "freshrss";
  };

  # PostgreSQL is configured globally in the host configuration

  # rss-bridge using the native NixOS module
  services.rss-bridge = {
    enable = true;
    webserver = "nginx";
    virtualHost = "rssbridge";
    config = {
      # Example: enable all bridges (optional)
      system.enabled_bridges = [ "*" ];
    };
  };

  services.nginx = {
    enable = true;
    virtualHosts.freshrss.listen = [
      {
        addr = "0.0.0.0";
        port = config.k.ports.freshrss_http;
      }
    ];
    virtualHosts.rssbridge.listen = [
      {
        addr = "0.0.0.0";
        port = config.k.ports.rssbridge_http;
      }
    ];
  };

  sops.secrets."freshrss/admin_password" = {
    owner = "freshrss";
  };

  networking.firewall.allowedTCPPorts = [
    config.k.ports.freshrss_http
    config.k.ports.rssbridge_http
  ];
}
