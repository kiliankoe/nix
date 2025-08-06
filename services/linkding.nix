{ config, pkgs, ... }:
let
  composeFile = pkgs.writeText "linkding-compose.yml" ''
    services:
      linkding:
        container_name: linkding
        image: sissbruecker/linkding:latest-plus
        volumes:
          - linkding-data:/etc/linkding/data
        restart: unless-stopped
        environment:
          - LD_CONTAINER_NAME=linkding
          - LD_HOST_PORT=9090
          - LD_HOST_DATA_DIR=./data
          - LD_DISABLE_BACKGROUND_TASKS=False
          - LD_DISABLE_URL_VALIDATION=False
          - LD_SUPERUSER_NAME=${builtins.readFile config.sops.secrets."linkding/superuser_name".path}
          - LD_SUPERUSER_PASSWORD=${
            builtins.readFile config.sops.secrets."linkding/superuser_password".path
          }
        ports:
          - '8381:9090'

    volumes:
      linkding-data:
  '';
in
{
  # Copy compose files to system
  environment.etc = {
    "docker-compose/linkding/docker-compose.yml".source = composeFile;
  };

  systemd.services.linkding = {
    description = "Docker Compose service for Linkding";
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      WorkingDirectory = "/etc/docker-compose/linkding";
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
    "d /etc/docker-compose/linkding 0755 root root -"
  ];
}
