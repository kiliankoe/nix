{ config, ... }:
{
  k.monitoring = {
    httpEndpoints = [
      {
        name = "sonarr";
        url = "http://localhost:${toString config.k.ports.sonarr_http}/";
      }
    ];
    systemdServices = [ "sonarr" ];
  };

  services.sonarr = {
    enable = true;
    group = "media";
    settings = {
      server.port = config.k.ports.sonarr_http;
      log.analyticsEnabled = false;
    };
  };

  networking.firewall.allowedTCPPorts = [ config.k.ports.sonarr_http ];
}
