{ config, pkgs, ... }:
{
  services.uptime-kuma = {
    enable = true;

    settings = {
      PORT = toString config.k.ports.uptime_kuma_http;
      HOST = "0.0.0.0";
    };
  };

  networking.firewall.allowedTCPPorts = [ config.k.ports.uptime_kuma_http ];
}
