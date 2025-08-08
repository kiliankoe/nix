{ config, pkgs, ... }:
{
  services.freshrss = {
    enable = true;

    baseUrl = "http://localhost:8380";

    database = {
      type = "pgsql";
      host = "localhost";
      port = null; # Use default PostgreSQL port
      user = "freshrss";
      name = "freshrss";
      passFile = pkgs.writeText "freshrss-db-pass" "freshrss"; # Simple password for local setup
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
        port = 8380;
      }
    ];
    virtualHosts.rssbridge.listen = [
      {
        addr = "0.0.0.0";
        port = 8384;
      }
    ];
  };

  networking.firewall.allowedTCPPorts = [
    8380
    8384
  ];
}
