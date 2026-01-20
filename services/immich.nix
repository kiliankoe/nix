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
  serviceName = "immich";
  auto_update = false;
  monitoring.httpEndpoint = {
    name = "immich";
    url = "http://localhost:${toString config.k.ports.immich_http}/";
  };
  compose = {
    services.immich-server = {
      image = "ghcr.io/immich-app/immich-server:release";
      container_name = "immich-server";
      volumes = [
        "/mnt/photos/immich:/usr/src/app/upload"
        "/etc/localtime:/etc/localtime:ro"
      ];
      env_file = [ "immich-server.env" ];
      ports = [ "${toString config.k.ports.immich_http}:2283" ];
      depends_on = {
        immich-redis.condition = "service_started";
        immich-postgres.condition = "service_healthy";
      };
      restart = "unless-stopped";
    };

    services.immich-machine-learning = {
      image = "ghcr.io/immich-app/immich-machine-learning:release";
      container_name = "immich-machine-learning";
      volumes = [ "immich-model-cache:/cache" ];
      env_file = [ "immich-machine-learning.env" ];
      restart = "unless-stopped";
    };

    services.immich-redis = {
      image = "docker.io/valkey/valkey:8-bookworm";
      container_name = "immich-redis";
      healthcheck = {
        test = [
          "CMD"
          "valkey-cli"
          "ping"
        ];
        interval = "10s";
        timeout = "5s";
        retries = 5;
      };
      restart = "unless-stopped";
    };

    services.immich-postgres = {
      image = "ghcr.io/immich-app/postgres:14-vectorchord0.3.0";
      container_name = "immich-postgres";
      env_file = [ "immich-postgres.env" ];
      volumes = [ "immich-postgres:/var/lib/postgresql/data" ];
      healthcheck = {
        test = [
          "CMD-SHELL"
          "pg_isready -d immich -U postgres"
        ];
        interval = "10s";
        timeout = "5s";
        retries = 5;
      };
      restart = "unless-stopped";
    };

    volumes = {
      immich-postgres = { };
      immich-model-cache = { };
    };
  };

  environment = {
    immich-server = {
      DB_PASSWORD.secret = "immich/db_password";
      DB_USERNAME = "postgres";
      DB_DATABASE_NAME = "immich";
      DB_HOSTNAME = "immich-postgres";
      REDIS_HOSTNAME = "immich-redis";
    };
    immich-machine-learning = {
      DB_PASSWORD.secret = "immich/db_password";
      DB_USERNAME = "postgres";
      DB_DATABASE_NAME = "immich";
      DB_HOSTNAME = "immich-postgres";
      REDIS_HOSTNAME = "immich-redis";
    };
    immich-postgres = {
      POSTGRES_PASSWORD.secret = "immich/db_password";
      POSTGRES_USER = "postgres";
      POSTGRES_DB = "immich";
    };
  };
}
