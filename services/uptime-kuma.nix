{ config, pkgs, ... }:
{
  services.uptime-kuma = {
    enable = true;

    settings = {
      PORT = toString config.k.ports.uptime_kuma;
      HOST = "0.0.0.0";
      # Data will be stored in /var/lib/uptime-kuma
    };
  };

  networking.firewall.allowedTCPPorts = [ config.k.ports.uptime_kuma ];
}
