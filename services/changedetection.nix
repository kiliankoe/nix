{ config, pkgs, ... }:
{
  services.changedetection-io = {
    enable = true;
    port = 5000;
    listenAddress = "0.0.0.0";

    playwrightSupport = true;

    datastorePath = "/var/lib/changedetection";

    environmentFile = pkgs.writeText "changedetection-env" ''
      TZ=${config.time.timeZone}
      FETCH_WORKERS=10
    '';
  };

  networking.firewall.allowedTCPPorts = [ 5000 ];
}
