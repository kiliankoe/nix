{ config, ... }:
{
  k.monitoring = {
    httpEndpoints = [
      {
        name = "uptime-kuma";
        url = "http://localhost:${toString config.k.ports.uptime_kuma_http}/";
      }
    ];
    systemdServices = [ "uptime-kuma" ];
  };

  services.uptime-kuma = {
    enable = true;

    settings = {
      PORT = toString config.k.ports.uptime_kuma_http;
      HOST = "0.0.0.0";
    };
  };

  networking.firewall.allowedTCPPorts = [ config.k.ports.uptime_kuma_http ];
}
