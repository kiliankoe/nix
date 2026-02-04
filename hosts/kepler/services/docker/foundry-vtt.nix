{
  config,
  pkgs,
  lib,
  ...
}:
let
  dockerService = import ../../../lib/docker-service.nix { inherit pkgs lib; };
in
dockerService.mkDockerComposeService {
  serviceName = "foundry-vtt";
  compose = {
    services.foundry = {
      container_name = "foundry";
      image = "felddy/foundryvtt:13";
      hostname = "foundry-vtt-host";
      restart = "unless-stopped";
      env_file = [ "foundry.env" ];
      volumes = [ "foundry-data:/data" ];
      ports = [ "${toString config.k.ports.foundry-vtt_http}:30000" ];
    };
    volumes.foundry-data = { };
  };
  environment = {
    foundry = {
      FOUNDRY_USERNAME.secret = "foundryvtt/username";
      FOUNDRY_PASSWORD.secret = "foundryvtt/password";
      FOUNDRY_ADMIN_KEY.secret = "foundryvtt/admin_key";
    };
  };
}
