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
        AuthSubnetWhitelistEnabled = true;
        AuthSubnetWhitelist = "127.0.0.1/32, 100.99.78.93/32";
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ config.k.ports.qbittorrent_http ];
}
