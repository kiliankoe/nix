{
  config,
  pkgs,
  lib,
  ...
}:
let
  dockerService = import ../../../../lib/docker-service.nix { inherit pkgs lib; };
in
lib.mkMerge [
  (dockerService.mkDockerComposeService {
    serviceName = "yamtrack";
    # Pinned + updated via Renovate PRs (renovate.json) instead of watchtower.
    auto_update = false;
    backupVolumes = [ "yamtrack-db" ];
    monitoring.httpEndpoint = {
      name = "yamtrack";
      url = "http://127.0.0.1:${toString config.k.ports.yamtrack_http}/";
    };
    compose = {
      services.yamtrack = {
        container_name = "yamtrack";
        # renovate
        image = "ghcr.io/fuzzygrim/yamtrack:0.25.3@sha256:00acf008bca8171226063bc0f8f08ef7ffe24a10bcebf8676cce335ce312c307";
        restart = "unless-stopped";
        depends_on = [ "yamtrack-redis" ];
        environment = [
          "TZ=${config.time.timeZone}"
          "REDIS_URL=redis://yamtrack-redis:6379"
          # Sets both ALLOWED_HOSTS and CSRF_TRUSTED_ORIGINS for the
          # reverse-proxied hostname.
          "URLS=https://yamtrack.kilko.de"
          # Single-tenant instance; existing users invite via admin.
          "REGISTRATION=False"
          "ADMIN_ENABLED=True"
        ];
        env_file = [ "yamtrack.env" ];
        volumes = [ "yamtrack-db:/yamtrack/db" ];
        ports = [ "${toString config.k.ports.yamtrack_http}:8000" ];
      };
      services.yamtrack-redis = {
        container_name = "yamtrack-redis";
        # renovate
        image = "redis:8-alpine@sha256:09160599abd229764c0fb44cb6be640294e1d360a54b19985ab4843dcf2d90f1";
        restart = "unless-stopped";
        volumes = [ "yamtrack-redis-data:/data" ];
      };
      volumes = {
        yamtrack-db = { };
        yamtrack-redis-data = { };
      };
    };
    environment = {
      yamtrack = {
        SECRET.secret = "yamtrack/secret";
        STEAM_API_KEY.secret = "yamtrack/steam_api_key";
      };
    };
  })
  {
    networking.firewall.allowedTCPPorts = [ config.k.ports.yamtrack_http ];
  }
]
