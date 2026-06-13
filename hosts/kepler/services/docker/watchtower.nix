{
  pkgs,
  lib,
  config,
  ...
}:
let
  dockerService = import ../../../../lib/docker-service.nix { inherit pkgs lib; };
  serviceDir = "/etc/docker-compose/watchtower";
in
lib.recursiveUpdate
  (dockerService.mkDockerComposeService {
    serviceName = "watchtower";
    monitoring.enable = false;
    # watchtower must not manage its own container: self-updates can cancel
    # an in-flight update batch and leave other containers stopped.
    auto_update = false;
    compose = {
      services.watchtower = {
        # renovate
        image = "nickfedor/watchtower:1.18.1@sha256:5a6262b7a66a353bd2cdb1e0cace6c5b7cb4d475d1080d6a57fe4ec82fe455b6";
        container_name = "watchtower";
        restart = "unless-stopped";
        volumes = [
          "/var/run/docker.sock:/var/run/docker.sock"
          "${serviceDir}/config.json:/config.json:ro"
        ];
        command = "--label-enable --interval 21600"; # 6 hours
      };
    };
  })
  {
    sops.secrets."watchtower/ghcr_auth" = { };

    systemd.services.watchtower = {
      serviceConfig.ExecStartPre = lib.mkBefore [
        (pkgs.writeScript "watchtower-generate-config" ''
          #!${pkgs.bash}/bin/bash
          AUTH=$(cat ${config.sops.secrets."watchtower/ghcr_auth".path})
          cat > ${serviceDir}/config.json <<EOF
          {
            "auths": {
              "ghcr.io": {
                "auth": "$AUTH"
              }
            }
          }
          EOF
          chmod 600 ${serviceDir}/config.json
        '')
      ];
    };
  }
