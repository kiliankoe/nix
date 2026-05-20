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
  serviceName = "plausible";
  auto_update = false;
  backupVolumes = [
    "plausible-db-data"
    "plausible-event-data"
    "plausible-event-logs"
    "plausible-data"
  ];
  monitoring.httpEndpoint = {
    name = "plausible";
    url = "http://localhost:${toString config.k.ports.plausible_http}/";
  };
  compose = {
    services.plausible-db = {
      # renovate
      image = "postgres:16-alpine@sha256:16bc17c64a573ef34162af9298258d1aec548232985b33ed7b1eac33ba35c229";
      container_name = "plausible-db";
      restart = "always";
      volumes = [ "plausible-db-data:/var/lib/postgresql/data" ];
      env_file = [ "plausible-db.env" ];
      healthcheck = {
        test = [
          "CMD-SHELL"
          "pg_isready -U postgres"
        ];
        interval = "10s";
        timeout = "5s";
        retries = 5;
        start_period = "60s";
      };
    };

    services.plausible-events-db = {
      # renovate
      image = "clickhouse/clickhouse-server:24.12-alpine@sha256:cd450891db46cc6ffe313ca2b0fb7dbfb897a6873ca74a724cbe050a2cf62621";
      container_name = "plausible-events-db";
      restart = "always";
      environment = {
        CLICKHOUSE_SKIP_USER_SETUP = "1";
      };
      volumes = [
        "plausible-event-data:/var/lib/clickhouse"
        "plausible-event-logs:/var/log/clickhouse-server"
      ];
      ulimits = {
        nofile = {
          soft = 262144;
          hard = 262144;
        };
      };
      healthcheck = {
        test = [
          "CMD-SHELL"
          "wget --no-verbose --tries=1 --spider http://127.0.0.1:8123/ping || exit 1"
        ];
        interval = "10s";
        timeout = "5s";
        retries = 5;
        start_period = "60s";
      };
    };

    services.plausible = {
      # renovate
      image = "ghcr.io/plausible/community-edition:v3.1.0@sha256:9703f89e41f7109bda6ae4fc64298474e8bc11f559e791cdda4b04218a92acb1";
      container_name = "plausible";
      restart = "always";
      command = [
        "sh"
        "-c"
        "/entrypoint.sh db createdb && /entrypoint.sh db migrate && /entrypoint.sh run"
      ];
      depends_on = {
        plausible-db.condition = "service_healthy";
        plausible-events-db.condition = "service_healthy";
      };
      ports = [ "${toString config.k.ports.plausible_http}:8000" ];
      env_file = [ "plausible.env" ];
      volumes = [ "plausible-data:/var/lib/plausible" ];
      ulimits = {
        nofile = {
          soft = 65535;
          hard = 65535;
        };
      };
    };

    volumes = {
      plausible-db-data = { };
      plausible-event-data = { };
      plausible-event-logs = { };
      plausible-data = { };
    };
  };

  environment = {
    plausible-db = {
      POSTGRES_PASSWORD.secret = "plausible/db_password";
      POSTGRES_USER = "postgres";
      POSTGRES_DB = "plausible_db";
    };
    plausible = {
      BASE_URL = "https://t.kilko.de";
      SECRET_KEY_BASE.secret = "plausible/secret_key_base";
      DISABLE_REGISTRATION = "true";
      DATABASE_URL.secret = "plausible/database_url";
      CLICKHOUSE_DATABASE_URL = "http://plausible-events-db:8123/plausible_events_db";
    };
  };
}
