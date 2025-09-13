{ config, pkgs, ... }:
{
  services.freshrss = {
    enable = true;

    baseUrl = "http://localhost:${toString config.k.ports.freshrss_http}";

    database = {
      type = "pgsql";
      host = "/run/postgresql";
      port = null; # Use default PostgreSQL port
      user = "freshrss";
      name = "freshrss";
    };

    defaultUser = "admin";
    passwordFile = pkgs.writeText "freshrss-admin-pass" "admin"; # Default admin password
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

  networking.firewall.allowedTCPPorts = [
    config.k.ports.freshrss_http
    config.k.ports.rssbridge_http
  ];
}
