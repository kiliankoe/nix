{ config, ... }:
{
  k.monitoring = {
    httpEndpoints = [
      {
        name = "lidarr";
        url = "http://localhost:${toString config.k.ports.lidarr_http}/";
      }
    ];
    systemdServices = [ "lidarr" ];
  };

  services.lidarr = {
    enable = true;
    group = "media";
    settings = {
      server.port = config.k.ports.lidarr_http;
      log.analyticsEnabled = false;
    };
  };

  networking.firewall.allowedTCPPorts = [ config.k.ports.lidarr_http ];
}
