{ config, pkgs, ... }:
let
  dockerService = import ../lib/docker-service.nix { inherit pkgs; };

  composeFile = pkgs.writeText "swiftdebot-compose.yml" ''
    services:
      swiftdebot:
        image: ghcr.io/swiftde/swiftdebot:latest
        container_name: swiftdebot
        restart: unless-stopped
        environment:
          - DISCORD_TOKEN=${builtins.readFile config.sops.secrets."swiftdebot/discord_token".path}
          - DISCORD_APP_ID=${builtins.readFile config.sops.secrets."swiftdebot/discord_app_id".path}
          - DISCORD_LOGS_WEBHOOK_URL=${
            builtins.readFile config.sops.secrets."swiftdebot/discord_logs_webhook_url".path
          }
          - KAGI_API_TOKEN=${builtins.readFile config.sops.secrets."swiftdebot/kagi_api_token".path}
          - OPENAI_API_TOKEN=${builtins.readFile config.sops.secrets."swiftdebot/openai_api_token".path}
  '';
in
dockerService.mkDockerComposeService {
  serviceName = "swiftdebot";
  composeFile = composeFile;
}
