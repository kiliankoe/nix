{ config, ... }:
{
  k.monitoring = {
    httpEndpoints = [
      {
        name = "qbittorrent";
        url = "http://127.0.0.1:${toString config.k.ports.qbittorrent_http}/";
      }
    ];
    systemdServices = [ "qbittorrent" ];
  };

  services.qbittorrent = {
    enable = true;
    group = "media";
    webuiPort = config.k.ports.qbittorrent_http;
    serverConfig = {
      BitTorrent.Session = {
        DefaultSavePath = "/mnt/media/download/complete";
        TempPath = "/mnt/media/download/incomplete";
        TempPathEnabled = true;
      };
      Preferences.WebUI = {
        CSRFProtection = true;
        HostHeaderValidation = true;
        ServerDomains = "qbit.kilko.de";
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ config.k.ports.qbittorrent_http ];
}
