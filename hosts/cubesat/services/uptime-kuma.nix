{ config, ... }:
{
  services.uptime-kuma = {
    enable = true;

    settings = {
      PORT = toString config.k.ports.uptime_kuma_http;
      HOST = "0.0.0.0";
    };
  };

  # open port only on tailscale0, never on the public WAN
  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [
    config.k.ports.uptime_kuma_http
  ];
}
