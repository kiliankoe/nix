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
      image = "docker.io/actualbudget/actual-server:26.5.2@sha256:1aeeb3985db55556e716dec25e08f6ce09308c2571b65cddbc6746ee6d5e0d45";
      restart = "unless-stopped";
      ports = [ "${toString config.k.ports.actual_http}:5006" ];
      volumes = [
        "actual-data:/data"
      ];
    };
    volumes.actual-data = { };
  };
}
