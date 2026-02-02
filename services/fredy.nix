{
  config,
  pkgs,
  lib,
  ...
}:
let
  dockerService = import ../lib/docker-service.nix { inherit pkgs lib; };
  serviceDir = "/etc/docker-compose/fredy";
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
      ports = [ "${toString config.k.ports.fredy_http}:4200" ];
      volumes = [
        "${serviceDir}/config.json:/conf/config.json:ro"
        "fredy-db:/db"
      ];
    };
    volumes.fredy-db = { };
  };
  extraFiles = {
    "docker-compose/fredy/config.json".text = ''
      {
        "sqlitepath": "/db"
      }
    '';
  };
}
