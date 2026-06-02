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
  serviceName = "actual";
  # Pinned + updated via Renovate PRs (renovate.json) instead of watchtower.
  auto_update = false;
  backupVolumes = [ "actual-data" ];
  monitoring.httpEndpoint = {
    name = "actual";
    url = "http://localhost:${toString config.k.ports.actual_http}/";
  };
  compose = {
    services.actual = {
      container_name = "actual";
      # renovate
      image = "docker.io/actualbudget/actual-server:26.6.0@sha256:74385f8067f401e61f0be9e343c471705c42dfaa195295c40c5b2f15f4dcc9d4";
      restart = "unless-stopped";
      ports = [ "${toString config.k.ports.actual_http}:5006" ];
      volumes = [
        "actual-data:/data"
      ];
    };
    volumes.actual-data = { };
  };
}
