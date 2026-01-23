{
  config,
  pkgs,
  lib,
  ...
}:
let
  dockerService = import ../lib/docker-service.nix { inherit pkgs lib; };
in
dockerService.mkDockerComposeService {
  serviceName = "goatcounter";
  auto_update = true;
  monitoring.httpEndpoint = {
    name = "goatcounter";
    url = "http://localhost:${toString config.k.ports.goatcounter_http}/";
  };
  compose = {
    services.goatcounter = {
      container_name = "goatcounter";
      image = "arp242/goatcounter:latest";
      volumes = [ "goatcounter-data:/home/goatcounter/goatcounter-data" ];
      restart = "unless-stopped";
      environment = [
        "GOATCOUNTER_LISTEN=:8080"
      ];
      ports = [ "${toString config.k.ports.goatcounter_http}:8080" ];
    };
    volumes.goatcounter-data = { };
  };
}
