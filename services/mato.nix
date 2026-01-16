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
  serviceName = "mato";
  auto_update = true;
  monitoring.httpEndpoint = {
    name = "mato";
    url = "http://localhost:${toString config.k.ports.mato_http}/";
  };
  compose = {
    services.app = {
      container_name = "mato";
      image = "ghcr.io/kiliankoe/mato:latest";
      restart = "unless-stopped";
      environment = [
        "TIMEZONE=${config.time.timeZone}"
        "DB_PATH=/data/db.json"
      ];
      env_file = [ "mato.env" ];
      volumes = [ "mato-data:/data" ];
      ports = [ "${toString config.k.ports.mato_http}:5050" ];
      healthcheck = {
        test = [
          "CMD"
          "curl"
          "-f"
          "http://127.0.0.1:5050/webhook"
        ];
        interval = "2s";
        timeout = "10s";
        retries = 15;
      };
    };
    volumes.mato-data = { };
  };
  environment = {
    mato = {
      MY_EMAIL.secret = "mato/my_email";
      SMTP_HOST.secret = "mato/smtp_host";
      SMTP_FROM.secret = "mato/smtp_from";
      SMTP_USER.secret = "mato/smtp_user";
      SMTP_PASS.secret = "mato/smtp_pass";
      CATFACT_SLACK_WEBHOOK_URL.secret = "mato/catfact_slack_webhook";
      JOBDIFF_SLACK_WEBHOOK_URL.secret = "mato/jobdiff_slack_webhook";
      KAGI_API_TOKEN.secret = "mato/kagi_api_token";
      PSYCHJOBS_RECIPIENT.secret = "mato/psychjobs_recipient";
      OPENAI_API_KEY.secret = "mato/openai_api_key";
    };
  };
}
