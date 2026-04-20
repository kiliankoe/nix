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
  auto_update = true;
  backupVolumes = [ "pinchflat-config" ];
  monitoring.httpEndpoint = {
    name = "pinchflat";
    url = "http://localhost:${toString config.k.ports.pinchflat_http}/";
  };
  compose = {
    services.pinchflat = {
      container_name = "pinchflat";
      image = "ghcr.io/kieraneglin/pinchflat:latest";
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
