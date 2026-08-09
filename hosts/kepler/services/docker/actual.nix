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
      image = "docker.io/actualbudget/actual-server:26.8.0@sha256:0b300f370dba85a74998a953736a831bd931cc8cb76c0d8ceac3d3fd288dfd4d";
      restart = "unless-stopped";
      ports = [ "${toString config.k.ports.actual_http}:5006" ];
      volumes = [
        "actual-data:/data"
      ];
    };
    volumes.actual-data = { };
  };
}
