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
  serviceName = "linkding";
  auto_update = true;
  monitoring.httpEndpoint = {
    name = "linkding";
    url = "http://localhost:${toString config.k.ports.linkding_http}/";
  };
  compose = {
    services.linkding = {
      container_name = "linkding";
      image = "sissbruecker/linkding:latest-plus";
      volumes = [ "linkding-data:/etc/linkding/data" ];
      restart = "unless-stopped";
      environment = [
        "LD_CONTAINER_NAME=linkding"
        "LD_HOST_PORT=9090"
        "LD_HOST_DATA_DIR=./data"
        "LD_DISABLE_BACKGROUND_TASKS=False"
        "LD_DISABLE_URL_VALIDATION=False"
      ];
      env_file = [ "linkding.env" ];
      ports = [ "${toString config.k.ports.linkding_http}:9090" ];
    };
    volumes.linkding-data = { };
  };
  environment = {
    linkding = {
      LD_SUPERUSER_NAME.secret = "linkding/superuser_name";
      LD_SUPERUSER_PASSWORD.secret = "linkding/superuser_password";
    };
  };
}
