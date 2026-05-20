{ config, pkgs, ... }:
{
  k.monitoring = {
    httpEndpoints = [
      {
        name = "jellyfin";
        url = "http://localhost:${toString config.k.ports.jellyfin_http}/web/";
      }
    ];
    systemdServices = [ "jellyfin" ];
  };

  services.jellyfin = {
    enable = true;
    # Primary group = media for read access to the /mnt/media CIFS mount
    # (media group has rwx via dir_mode/file_mode=0775), matching sonarr.
    group = "media";
    # openFirewall stays false: it would open 8096/8920/1900/7359.
  };

  # Intel Quick Sync (VA-API) hardware transcoding — mirrors archived Plex
  # config. Enable QSV/VA-API inside Jellyfin's admin UI after deploy.
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # Broadwell+ Intel iGPUs
      intel-vaapi-driver # older Intel iGPUs
    ];
  };
  users.users.jellyfin.extraGroups = [
    "render"
    "video"
  ];

  # Reverse proxy: nginx :8412 -> Jellyfin 127.0.0.1:8096.
  # The services.jellyfin module exposes no port option, so we front it with
  # nginx (already enabled on kepler via freshrss) to land on a registered port.
  services.nginx = {
    enable = true;
    virtualHosts."jellyfin" = {
      listen = [
        {
          addr = "0.0.0.0";
          port = config.k.ports.jellyfin_http;
        }
      ];
      extraConfig = ''
        client_max_body_size 0;
      '';
      locations."/" = {
        proxyPass = "http://127.0.0.1:8096";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
          proxy_set_header X-Forwarded-Host $http_host;
          proxy_buffering off;
        '';
      };
    };
  };

  # Open only the proxied port; Jellyfin's own 8096 stays loopback-only.
  networking.firewall.allowedTCPPorts = [ config.k.ports.jellyfin_http ];
}
