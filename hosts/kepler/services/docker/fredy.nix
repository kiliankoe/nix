{
  config,
  pkgs,
  lib,
  ...
}:
let
  dockerService = import ../../../lib/docker-service.nix { inherit pkgs lib; };
in
dockerService.mkDockerComposeService {
  serviceName = "fredy";
  auto_update = true;
  monitoring.httpEndpoint = {
    name = "fredy";
    url = "http://localhost:${toString config.k.ports.fredy_http}/";
  };
  compose = {
    services.fredy = {
      container_name = "fredy";
      image = "ghcr.io/orangecoding/fredy:latest";
      restart = "unless-stopped";
      ports = [ "${toString config.k.ports.fredy_http}:9998" ];
      volumes = [
        "fredy-conf:/conf"
        "fredy-db:/db"
      ];
    };
    volumes.fredy-conf = { };
    volumes.fredy-db = { };
  };
}
