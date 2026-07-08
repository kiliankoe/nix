{ config, inputs, ... }:
{
  imports = [ inputs.hister.nixosModules.default ];

  k.monitoring = {
    httpEndpoints = [
      {
        name = "hister";
        url = "http://0.0.0.0:${toString config.k.ports.hister_http}/api/config";
      }
    ];
    systemdServices = [ "hister" ];
  };

  services.hister = {
    enable = true;

    dataDir = "/var/lib/hister";

    settings = {
      app = {
        search_url = "https://kagi.com/search?q={query}";
      };

      server = {
        address = "0.0.0.0:${toString config.k.ports.hister_http}";
        base_url = "http://kepler:${toString config.k.ports.hister_http}";
      };

      extractors.ytdlp = {
        enable = true;
        options.fetch_subtitles = true;
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/hister 0750 hister hister -"
  ];

  # tailnet-only
  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [
    config.k.ports.hister_http
  ];
}
