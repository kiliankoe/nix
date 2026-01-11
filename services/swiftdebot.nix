{
  pkgs,
  lib,
  ...
}:
let
  dockerService = import ../lib/docker-service.nix { inherit pkgs lib; };
in
dockerService.mkDockerComposeService {
  serviceName = "swiftdebot";
  compose = {
    services.swiftdebot = {
      image = "ghcr.io/swiftde/swiftdebot:latest";
      container_name = "swiftdebot";
      restart = "unless-stopped";
      env_file = [ "swiftdebot.env" ];
      labels = [ "com.centurylinklabs.watchtower.enable=true" ];
    };
  };
  environment = {
    swiftdebot = {
      DISCORD_TOKEN.secret = "swiftdebot/discord_token";
      DISCORD_APP_ID.secret = "swiftdebot/discord_app_id";
      DISCORD_LOGS_WEBHOOK_URL.secret = "swiftdebot/discord_logs_webhook_url";
      KAGI_API_TOKEN.secret = "swiftdebot/kagi_api_token";
      OPENAI_API_TOKEN.secret = "swiftdebot/openai_api_token";
    };
  };
}
