{ config, ... }:
{
  services.cockpit = {
    enable = true;
    port = config.k.ports.cockpit_http;
    openFirewall = true;

    settings = {
      WebService = {
        AllowUnencrypted = true;
      };
    };
  };
}
