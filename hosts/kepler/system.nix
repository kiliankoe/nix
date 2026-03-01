{ pkgs, ... }:
{
  networking.hostName = "kepler";

  # db shared by multiple services
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;

    # Ensure all required databases and users exist
    ensureDatabases = [
      "freshrss"
      "paperless"
    ];
    ensureUsers = [
      {
        name = "freshrss";
        ensureDBOwnership = true;
      }
      {
        name = "paperless";
        ensureDBOwnership = true;
      }
    ];
  };

  sops.secrets = {
    "kepler_backup/server" = { };
    "kepler_backup/username" = { };
    "kepler_backup/password" = { };
    "synology/smb_username" = { };
    "synology/smb_password" = { };
  };

  # Shared group for media services (sabnzbd, sonarr, radarr) to access NAS mount
  users.groups.media.gid = 1500;
  users.users.sabnzbd.extraGroups = [ "media" ];
  users.users.sonarr.extraGroups = [ "media" ];
  users.users.radarr.extraGroups = [ "media" ];

  # Disable power management (server)
  powerManagement.enable = false;
  # Set CPU governor to performance for better responsiveness
  powerManagement.cpuFreqGovernor = "performance";

  # Add swap to prevent performance degradation under memory pressure
  swapDevices = [
    {
      device = "/swapfile";
      size = 8192;
    }
  ];

  # WebDAV mount for Tailscale
  # services.davfs2.enable = true;
  # fileSystems."/mnt/tailscale" = {
  #   device = "none";
  #   fsType = "tmpfs";
  #   options = [ "defaults" ];
  # };

  # systemd.mounts = [
  #   {
  #     enable = true;
  #     description = "Tailscale Drive WebDAV mount";
  #     after = [ "network-online.target" ];
  #     wants = [ "network-online.target" ];
  #     what = "http://100.100.100.100:8080";
  #     where = "/mnt/tailscale";
  #     options = "uid=1000,gid=100,file_mode=0664,dir_mode=0775,_netdev";
  #     type = "davfs";
  #     mountConfig.TimeoutSec = 30;
  #   }
  # ];

  services.cron = {
    enable = true;
    systemCronJobs = [
      # "0 4 * * 1      kilian    sudo rsync -av --progress html /mnt/tailscale/kiliankoe.github/marvin/backups/nextcloud/"
    ];
  };

  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="04b8", ATTR{idProduct}=="0e28", MODE="0666"
  '';
}
