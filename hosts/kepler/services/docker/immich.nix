{
  config,
  pkgs,
  lib,
  ...
}:
let
  dockerService = import ../../../../lib/docker-service.nix { inherit pkgs lib; };
in
dockerService.mkDockerComposeService {
  serviceName = "immich";
  auto_update = false;
  backupVolumes = [
    "immich-postgres"
    "immich-model-cache"
  ];
  monitoring.httpEndpoint = {
    name = "immich";
    url = "http://localhost:${toString config.k.ports.immich_http}/";
  };
  compose = {
    services.immich-server = {
      # renovate
      image = "ghcr.io/immich-app/immich-server:release@sha256:e6a6298e67ae077808fdb7d8d5565955f60b0708191576143fc02d30ab1389d1";
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
      # renovate
      image = "ghcr.io/immich-app/immich-machine-learning:release@sha256:b3deefd1826f113824e9d7bc30d905e7f823535887d03f869330946b6db3b44a";
      container_name = "immich-machine-learning";
      volumes = [ "immich-model-cache:/cache" ];
      env_file = [ "immich-machine-learning.env" ];
      restart = "unless-stopped";
    };

    services.immich-redis = {
      # renovate
      image = "docker.io/valkey/valkey:8-bookworm@sha256:fea8b3e67b15729d4bb70589eb03367bab9ad1ee89c876f54327fc7c6e618571";
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
      # renovate
      image = "ghcr.io/immich-app/postgres:14-vectorchord0.3.0@sha256:6f3e9d2c2177af16c2988ff71425d79d89ca630ec2f9c8db03209ab716542338";
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
