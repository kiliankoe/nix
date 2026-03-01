{ config, ... }:
{
  k.monitoring = {
    httpEndpoints = [
      {
        name = "sabnzbd";
        url = "http://localhost:${toString config.k.ports.sabnzbd_http}/";
      }
    ];
    systemdServices = [ "sabnzbd" ];
  };

  services.sabnzbd = {
    enable = true;
    group = "media";
    settings.misc = {
      port = config.k.ports.sabnzbd_http;
      host = "0.0.0.0";
      download_dir = "/mnt/media/download/incomplete";
      complete_dir = "/mnt/media/download/complete";
    };
  };

  networking.firewall.allowedTCPPorts = [ config.k.ports.sabnzbd_http ];
}
