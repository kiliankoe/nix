{ config, pkgs, ... }:
{
  services.factorio = {
    enable = true;

    port = 34197;
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

  networking.firewall.allowedUDPPorts = [ 34197 ];
}
