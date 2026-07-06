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

  sops.secrets."hister/access_token" = { };

  sops.templates."hister-env".content = ''
    HISTER__APP__ACCESS_TOKEN=${config.sops.placeholder."hister/access_token"}
  '';

  services.hister = {
    enable = true;

    dataDir = "/var/lib/hister";
    environmentFile = config.sops.templates."hister-env".path;

    settings = {
      server = {
        address = "0.0.0.0:${toString config.k.ports.hister_http}";
        base_url = "http://kepler:${toString config.k.ports.hister_http}";
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
