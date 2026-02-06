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
  auto_update = true;
  monitoring.httpEndpoint = {
    name = "actual";
    url = "http://localhost:${toString config.k.ports.actual_http}/";
  };
  compose = {
    services.actual = {
      container_name = "actual";
      image = "docker.io/actualbudget/actual-server:latest";
      restart = "unless-stopped";
      ports = [ "${toString config.k.ports.fredy_http}:5006" ];
      volumes = [
        "actual-data:/data"
      ];
    };
    volumes.actual-data = { };
  };
}
