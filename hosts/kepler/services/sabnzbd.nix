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
    # Both default to legacy behavior on stateVersion < 26.05, which breaks
    # first-run and ignores settings. Explicitly opt into the new mode.
    configFile = null;
    allowConfigWrite = false;
    settings.misc = {
      port = config.k.ports.sabnzbd_http;
      host = "0.0.0.0";
      host_whitelist = "kepler, kepler.local";
      inet_exposure = "api+web (locally no auth)";
      download_dir = "/mnt/media/download/incomplete";
      complete_dir = "/mnt/media/download/complete";
    };
  };

  networking.firewall.allowedTCPPorts = [ config.k.ports.sabnzbd_http ];
}
