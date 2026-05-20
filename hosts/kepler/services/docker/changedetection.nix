{
  config,
  pkgs,
  lib,
  ...
}:
let
  dockerService = import ../../../../lib/docker-service.nix { inherit pkgs lib; };
in
dockerService.mkDockerComposeService {
  serviceName = "changedetection";
  # Pinned + updated via Renovate PRs (renovate.json) instead of watchtower.
  auto_update = false;
  backupVolumes = [ "changedetection-data" ];
  monitoring.httpEndpoint = {
    name = "changedetection";
    url = "http://localhost:${toString config.k.ports.changedetection_http}/";
  };
  compose = {
    services.changedetection = {
      # renovate
      image = "ghcr.io/dgtlmoon/changedetection.io:0.55.5@sha256:d89d4187221206f7f9f2c7946e7483815db905ca7d122644081aebd5d23ba391";
      container_name = "changedetection";
      hostname = "changedetection";
      restart = "unless-stopped";
      security_opt = [ "no-new-privileges:true" ];
      environment = [
        "TZ=${config.time.timeZone}"
        "FETCH_WORKERS=10"
        "PLAYWRIGHT_DRIVER_URL=ws://sockpuppetbrowser:3000"
        "SCREEN_WIDTH=1920"
        "SCREEN_HEIGHT=1024"
      ];
      volumes = [ "changedetection-data:/datastore" ];
      ports = [ "${toString config.k.ports.changedetection_http}:5000" ];
      depends_on.sockpuppetbrowser.condition = "service_started";
    };
    services.sockpuppetbrowser = {
      # renovate
      image = "dgtlmoon/sockpuppetbrowser:latest@sha256:7116c61ef9cfce3d48a7efd9355d2fbe19f593ea3cfb52a5ded40ecbcb0a3f9d";
      container_name = "changedetection-browser";
      hostname = "sockpuppetbrowser";
      restart = "unless-stopped";
      security_opt = [ "no-new-privileges:true" ];
      cap_add = [ "SYS_ADMIN" ];
      environment = [
        "SCREEN_WIDTH=1920"
        "SCREEN_HEIGHT=1024"
        "SCREEN_DEPTH=16"
        "MAX_CONCURRENT_CHROME_PROCESSES=10"
      ];
    };
    volumes.changedetection-data = { };
  };
}
