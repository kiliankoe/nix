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
  serviceName = "jobfinder";
  auto_update = true;
  backupVolumes = [ "jobfinder-pb-data" ];
  monitoring.httpEndpoint = {
    name = "jobfinder";
    url = "http://localhost:${toString config.k.ports.jobfinder_http}/";
  };
  compose = {
    services.pocketbase = {
      image = "ghcr.io/kiliankoe/jobfinder/pocketbase:latest";
      container_name = "jobfinder-pocketbase";
      restart = "unless-stopped";
      volumes = [ "jobfinder-pb-data:/pb/pb_data" ];
      env_file = [ "pocketbase.env" ];
      healthcheck = {
        test = [
          "CMD"
          "wget"
          "--no-verbose"
          "--tries=1"
          "--spider"
          "http://localhost:8090/api/health"
        ];
        interval = "5s";
        timeout = "3s";
        retries = 5;
      };
    };
    services.runner = {
      image = "ghcr.io/kiliankoe/jobfinder/runner:latest";
      container_name = "jobfinder-runner";
      restart = "unless-stopped";
      env_file = [ "runner.env" ];
      depends_on.pocketbase.condition = "service_healthy";
    };
    services.frontend = {
      image = "ghcr.io/kiliankoe/jobfinder/frontend:latest";
      container_name = "jobfinder-frontend";
      restart = "unless-stopped";
      ports = [ "${toString config.k.ports.jobfinder_http}:5173" ];
      depends_on.pocketbase.condition = "service_started";
    };
    volumes.jobfinder-pb-data = { };
  };
  environment = {
    pocketbase = {
      PB_ADMIN_EMAIL.secret = "jobfinder/pb_admin_email";
      PB_ADMIN_PASSWORD.secret = "jobfinder/pb_admin_password";
    };
    runner = {
      POCKETBASE_URL = "http://pocketbase:8090";
      PB_ADMIN_EMAIL.secret = "jobfinder/pb_admin_email";
      PB_ADMIN_PASSWORD.secret = "jobfinder/pb_admin_password";
      OPENAI_API_KEY.secret = "jobfinder/openai_api_key";
      KAGI_API_TOKEN.secret = "jobfinder/kagi_api_token";
    };
  };
}
