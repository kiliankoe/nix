{ config, ... }:
{
  services.factorio = {
    enable = true;

    port = config.k.ports.factorio_udp;
    bind = "0.0.0.0";

    game-name = "Benjamilius";
    saveName = "Benjamilius";
    # description = "Nix-managed Factorio server";
    public = false;
    lan = true;
    requireUserVerification = true;

    extraSettings = {
      game = {
        autosave-interval = 5;
        autosave-slots = 10;
      };
    };
  };

  networking.firewall.allowedUDPPorts = [ config.k.ports.factorio_udp ];
}
