{ config, pkgs, ... }:
let
  composeFile = pkgs.writeText "changedetection-compose.yml" ''
    services:
      changedetection:
        image: ghcr.io/dgtlmoon/changedetection.io
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
          - PLAYWRIGHT_DRIVER_URL=ws://sockpuppetbrowser:3000
          - FETCH_WORKERS=10
          - TZ=Europe/Berlin
        env_file:
          - .env
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
{
  # Copy compose files to system
  environment.etc = {
    "docker-compose/changedetection/docker-compose.yml".source = composeFile;
  };

  systemd.services.changedetection = {
    description = "Docker Compose service for Changedetection.io";
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      WorkingDirectory = "/etc/docker-compose/changedetection";
      ExecStart = "${pkgs.docker-compose}/bin/docker-compose up -d";
      ExecStop = "${pkgs.docker-compose}/bin/docker-compose down";
      ExecReload = "${pkgs.docker-compose}/bin/docker-compose up -d --force-recreate";
      TimeoutStartSec = 0;
      User = "root";
    };

    unitConfig = {
      StartLimitBurst = 3;
      StartLimitIntervalSec = 60;
    };
  };

  # Create secrets symlink for .env file
  systemd.tmpfiles.rules = [
    "d /etc/docker-compose/changedetection 0755 root root -"
    "L+ /etc/docker-compose/changedetection/.env - - - - /home/kilian/.config/secrets/changedetection.env"
  ];
}
