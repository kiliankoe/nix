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
      image = "docker.io/actualbudget/actual-server:26.7.0@sha256:e18b7fbfec6157a368fad4146563f397502e9da70a120aeaeac63b4977405d1c";
      restart = "unless-stopped";
      ports = [ "${toString config.k.ports.actual_http}:5006" ];
      volumes = [
        "actual-data:/data"
      ];
    };
    volumes.actual-data = { };
  };
}
