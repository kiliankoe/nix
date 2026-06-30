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
        image = "nickfedor/watchtower:1.19.0@sha256:c1dfdf27fe805dcfefe1cf048cee6960a511c097a99aa355b0bc4be6e6bb3bdf";
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
