{ config, pkgs, ... }:
let
  composeFile = pkgs.writeText "freshrss-compose.yml" ''
    services:
      freshrss:
        image: freshrss/freshrss:edge
        container_name: freshrss
        restart: unless-stopped
        security_opt:
          - "no-new-privileges:true"
        depends_on:
          - rss-bridge
        logging:
          options:
            max-size: 10m
        volumes:
          - freshrss-data:/var/www/FreshRSS/data
          - freshrss-extensions:/var/www/FreshRSS/extensions
        environment:
          - TZ=Europe/Berlin
          - CRON_MIN=13,43
        ports:
          - '8383:80'

      rss-bridge:
        image: rssbridge/rss-bridge:latest
        container_name: rss-bridge
        restart: unless-stopped
        security_opt:
          - "no-new-privileges:true"
        logging:
          options:
            max-size: 10m
        volumes:
          - rss-bridge-config:/config
        environment:
          - RSSBRIDGE_AUTH_USER=${
            builtins.readFile config.sops.secrets."freshrss/rssbridge_auth_user".path
          }
          - RSSBRIDGE_AUTH_HASH=${
            builtins.readFile config.sops.secrets."freshrss/rssbridge_auth_hash".path
          }
        ports:
          - '8384:80'

    volumes:
      freshrss-data:
      freshrss-extensions:
      rss-bridge-config:
  '';
in
{
  # Copy compose files to system
  environment.etc = {
    "docker-compose/freshrss/docker-compose.yml".source = composeFile;
  };

  systemd.services.freshrss = {
    description = "Docker Compose service for FreshRSS";
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      WorkingDirectory = "/etc/docker-compose/freshrss";
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

  # Create directory for compose files
  systemd.tmpfiles.rules = [
    "d /etc/docker-compose/freshrss 0755 root root -"
  ];
}
