{ config, pkgs, ... }:
{
  # Enable Intel Quick Sync (VA-API) for hardware transcoding
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # For newer Intel CPUs (Broadwell+)
      intel-vaapi-driver # For older Intel CPUs
    ];
  };

  services.plex = {
    enable = true;
    openFirewall = true;
    user = "plex";
    group = "plex";
    # Enable hardware transcoding via Intel Quick Sync
    accelerationDevices = [ "/dev/dri/renderD128" ];
  };

  # Ensure plex user can access the render device
  users.users.plex.extraGroups = [
    "render"
    "video"
  ];

  # Register for monitoring
  k.monitoring = {
    httpEndpoints = [
      {
        name = "plex";
        url = "http://localhost:${toString config.k.ports.plex_http}/web/";
      }
    ];
    systemdServices = [ "plex" ];
  };
}
