{ config, pkgs, lib, ... }:
let
  dockerService = import ../lib/docker-service.nix { inherit pkgs lib; };
in
dockerService.mkDockerComposeService {
  serviceName = "linkding";
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
  volumesToBackup = [ "linkding-data" ];
  environment = {
    linkding = {
      LD_SUPERUSER_NAME = {
        secretFile = config.sops.secrets."linkding/superuser_name".path;
      };
      LD_SUPERUSER_PASSWORD = {
        secretFile = config.sops.secrets."linkding/superuser_password".path;
      };
    };
  };
}
