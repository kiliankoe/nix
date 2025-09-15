{ config, pkgs, ... }:
let
  dockerService = import ../lib/docker-service.nix { inherit pkgs; };

  composeFile = pkgs.writeText "foundry-vtt-compose.yml" ''
    services:
      foundry:
        image: felddy/foundryvtt:13
        hostname: foundry-vtt-host
        restart: unless-stopped
        env_file:
          - foundry.env
        volumes:
          - foundry-data:/data
        ports:
          - '${toString config.k.ports.foundry-vtt_http}:30000'

    volumes:
      foundry-data:
  '';
in
dockerService.mkDockerComposeService {
  serviceName = "foundry-vtt";
  composeFile = composeFile;
  environment = {
    foundry = {
      FOUNDRY_USERNAME = {
        secretFile = config.sops.secrets."foundryvtt/username".path;
      };
      FOUNDRY_PASSWORD = {
        secretFile = config.sops.secrets."foundryvtt/password".path;
      };
      FOUNDRY_ADMIN_KEY = {
        secretFile = config.sops.secrets."foundryvtt/admin_key".path;
      };
    };
  };
  # volumesToBackup = [ "foundry-data" ];
}
