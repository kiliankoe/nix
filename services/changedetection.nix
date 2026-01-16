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
  serviceName = "changedetection";
  auto_update = true;
  monitoring.httpEndpoint = {
    name = "changedetection";
    url = "http://localhost:${toString config.k.ports.changedetection_http}/";
  };
  compose = {
    services.changedetection = {
      image = "ghcr.io/dgtlmoon/changedetection.io:latest";
      container_name = "changedetection";
      hostname = "changedetection";
      restart = "unless-stopped";
      security_opt = [ "no-new-privileges:true" ];
      environment = [
        "TZ=${config.time.timeZone}"
        "FETCH_WORKERS=10"
        "PLAYWRIGHT_DRIVER_URL=ws://sockpuppetbrowser:3000"
        "SCREEN_WIDTH=1920"
        "SCREEN_HEIGHT=1024"
      ];
      volumes = [ "changedetection-data:/datastore" ];
      ports = [ "${toString config.k.ports.changedetection_http}:5000" ];
      depends_on.sockpuppetbrowser.condition = "service_started";
    };
    services.sockpuppetbrowser = {
      image = "dgtlmoon/sockpuppetbrowser:latest";
      container_name = "changedetection-browser";
      hostname = "sockpuppetbrowser";
      restart = "unless-stopped";
      security_opt = [ "no-new-privileges:true" ];
      cap_add = [ "SYS_ADMIN" ];
      environment = [
        "SCREEN_WIDTH=1920"
        "SCREEN_HEIGHT=1024"
        "SCREEN_DEPTH=16"
        "MAX_CONCURRENT_CHROME_PROCESSES=10"
      ];
    };
    volumes.changedetection-data = { };
  };
}
