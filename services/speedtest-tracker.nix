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
  auto_update = true;
  monitoring = {
    name = "speedtest-tracker";
    url = "https://speedtest.kilko.de";
  };
  compose = {
    services.speedtest-tracker = {
      container_name = "speedtest-tracker";
      image = "lscr.io/linuxserver/speedtest-tracker:latest";
      restart = "unless-stopped";
      environment = [
        "PUID=1000"
        "PGID=1000"
        "DB_CONNECTION=sqlite"
        "APP_URL=https://speedtest.kilko.de"
        "DISPLAY_TIMEZONE=Europe/Berlin"
        "SPEEDTEST_SCHEDULE=8 * * * *"
        # See https://c.speedtest.net/speedtest-servers-static.php
        "SPEEDTEST_SERVERS=30907,2495,11187,17301,69560,11519,68491,49678"
        "PUBLIC_DASHBOARD=true"
      ];
      env_file = [ "speedtest-tracker.env" ];
      volumes = [ "speedtest-tracker-data:/config" ];
      ports = [ "${toString config.k.ports.speedtest_tracker_http}:80" ];
    };
    volumes.speedtest-tracker-data = { };
  };
  environment = {
    speedtest-tracker = {
      APP_KEY.secret = "speedtest_tracker/app_key";
    };
  };
}
