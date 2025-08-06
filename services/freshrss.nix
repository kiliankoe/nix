{ config, pkgs, ... }:
let
  dockerService = import ../lib/docker-service.nix { inherit pkgs; };

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
          - TZ=${config.time.timeZone}
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
        env_file:
          - rss-bridge.env
        ports:
          - '8384:80'

    volumes:
      freshrss-data:
      freshrss-extensions:
      rss-bridge-config:
  '';
in
dockerService.mkDockerComposeService {
  serviceName = "freshrss";
  composeFile = composeFile;
  environment = {
    rss-bridge = {
      RSSBRIDGE_AUTH_USER = {
        secretFile = config.sops.secrets."freshrss/rssbridge_auth_user".path;
      };
      RSSBRIDGE_AUTH_HASH = {
        secretFile = config.sops.secrets."freshrss/rssbridge_auth_hash".path;
      };
    };
  };
}
