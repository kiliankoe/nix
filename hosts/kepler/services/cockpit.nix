{ config, lib, ... }:
{
  services.cockpit = {
    enable = false;
    port = config.k.ports.cockpit_http;
    openFirewall = true;

    settings = {
      WebService = {
        AllowUnencrypted = true;
        Origins = lib.mkForce "http://kepler:${toString config.k.ports.cockpit_http}";
      };
    };
  };
}
