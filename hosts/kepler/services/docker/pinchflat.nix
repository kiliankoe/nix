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
  serviceName = "pinchflat";
  # Pinned + updated via Renovate PRs (renovate.json) instead of watchtower.
  auto_update = false;
  backupVolumes = [ "pinchflat-config" ];
  monitoring.httpEndpoint = {
    name = "pinchflat";
    url = "http://localhost:${toString config.k.ports.pinchflat_http}/";
  };
  compose = {
    services.pinchflat = {
      container_name = "pinchflat";
      # renovate
      image = "ghcr.io/kieraneglin/pinchflat:latest@sha256:01b4f98aabaf3f5fe394213f7a32578c9e84e42080f52e2f8334021a4473b202";
      restart = "unless-stopped";
      environment = [
        "TZ=${config.time.timeZone}"
        "LOG_LEVEL=info"
        "EXPOSE_FEED_ENDPOINTS=true"
      ];
      volumes = [
        "pinchflat-config:/config"
        "/mnt/media/YouTube:/downloads"
      ];
      ports = [ "${toString config.k.ports.pinchflat_http}:8945" ];
    };
    volumes.pinchflat-config = { };
  };
}
