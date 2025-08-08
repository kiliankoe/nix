{ config, pkgs, ... }:
{
  services.uptime-kuma = {
    enable = true;

    settings = {
      PORT = "3001";
      HOST = "0.0.0.0";
      # Data will be stored in /var/lib/uptime-kuma
    };
  };

  networking.firewall.allowedTCPPorts = [ 3001 ];
}
