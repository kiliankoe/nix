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
  serviceName = "speedtest-tracker";
  compose = {
    services.speedtest-tracker = {
      container_name = "speedtest-tracker";
      image = "lscr.io/linuxserver/speedtest-tracker:latest";
      restart = "unless-stopped";
      environment = [
        "PUID=1000"
        "PGID=1000"
        "DB_CONNECTION=sqlite"
      ];
      env_file = [ "speedtest-tracker.env" ];
      volumes = [ "speedtest-tracker-data:/config" ];
      ports = [ "${toString config.k.ports.speedtest_tracker_http}:80" ];
      labels = [ "com.centurylinklabs.watchtower.enable=true" ];
    };
    volumes.speedtest-tracker-data = { };
  };
  environment = {
    speedtest-tracker = {
      APP_KEY.secret = "speedtest_tracker/app_key";
    };
  };
}
