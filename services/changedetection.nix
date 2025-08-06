{ config, pkgs, ... }:
let
  dockerService = import ../lib/docker-service.nix { inherit pkgs; };

  composeFile = pkgs.writeText "changedetection-compose.yml" ''
    services:
      changedetection:
        image: ghcr.io/dgtlmoon/changedetection.io:latest
        container_name: changedetection
        hostname: changedetection
        volumes:
          - changedetection-data:/datastore
        ports:
          - '5000:5000'
        restart: unless-stopped
        security_opt:
          - "no-new-privileges:true"
        environment:
          - TZ=${config.time.timeZone}
          - PLAYWRIGHT_DRIVER_URL=ws://sockpuppetbrowser:3000
          - FETCH_WORKERS=10
        depends_on:
          sockpuppetbrowser:
            condition: service_started

      sockpuppetbrowser:
        image: dgtlmoon/sockpuppetbrowser:latest
        container_name: changedetection-browser
        hostname: sockpuppetbrowser
        restart: unless-stopped
        security_opt:
          - "no-new-privileges:true"
        cap_add:
          - SYS_ADMIN
        environment:
          - SCREEN_WIDTH=1920
          - SCREEN_HEIGHT=1024
          - SCREEN_DEPTH=16
          - MAX_CONCURRENT_CHROME_PROCESSES=10

    volumes:
      changedetection-data:
  '';
in
dockerService.mkDockerComposeService {
  serviceName = "changedetection";
  composeFile = composeFile;
}
