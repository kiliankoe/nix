{ config, ... }:
{
  k.monitoring = {
    httpEndpoints = [
      {
        name = "radarr";
        url = "http://localhost:${toString config.k.ports.radarr_http}/";
      }
    ];
    systemdServices = [ "radarr" ];
  };

  services.radarr = {
    enable = true;
    group = "media";
    settings = {
      server.port = config.k.ports.radarr_http;
      log.analyticsEnabled = false;
    };
  };

  networking.firewall.allowedTCPPorts = [ config.k.ports.radarr_http ];
}
