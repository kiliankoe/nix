{ pkgs, lib }:

let
  yamlFormat = pkgs.formats.yaml { };
in
{
  # Creates a standardized Docker Compose service
  # serviceName: Name of the service
  # compose: Attrset representing the docker-compose.yml structure
  # extraFiles: Optional attrset of additional files to copy
  # environment: Optional attrset of service-scoped environment variables and secrets
  #   Format: { serviceName = { VAR = value; SECRET = { secret = "name"; }; }; }
  #   Secrets are auto-declared in sops.secrets and paths are resolved automatically
  mkDockerComposeService =
    {
      serviceName,
      compose,
      extraFiles ? { },
      environment ? { },
    }:
    let
      serviceDir = "/etc/docker-compose/${serviceName}";

      # Extract secret names from environment
      extractSecretNames =
        envVars:
        lib.filter (x: x != null) (
          lib.mapAttrsToList (
            _: value: if builtins.isAttrs value && value ? secret then value.secret else null
          ) envVars
        );

      # Collect all secret names from all service environments
      allSecretNames = lib.flatten (lib.mapAttrsToList (_: extractSecretNames) environment);

      # Create environment file scripts for each service
      envScripts = builtins.mapAttrs (
        svcName: envVars:
        pkgs.writeScript "${serviceName}-${svcName}-env" ''
          #!/bin/sh
          ${builtins.concatStringsSep "\n" (
            builtins.attrValues (
              builtins.mapAttrs (
                name: value:
                if builtins.isAttrs value && value ? secret then
                  "echo \"${name}=$(cat /run/secrets/${value.secret})\""
                else
                  "echo \"${name}=${toString value}\""
              ) envVars
            )
          )}
        ''
      ) environment;

      # Generate ExecStartPre commands to create .env files
      envFileCommands = builtins.attrValues (
        builtins.mapAttrs (
          svcName: script: "${pkgs.bash}/bin/bash -c '${script} > ${serviceDir}/${svcName}.env'"
        ) envScripts
      );

      composeFile = yamlFormat.generate "${serviceName}-compose.yml" compose;
    in
    {
      # Copy compose files to system
      environment.etc = {
        "docker-compose/${serviceName}/docker-compose.yml".source = composeFile;
      }
      // extraFiles;

      systemd.services.${serviceName} = {
        description = "Docker Compose service for ${serviceName}";
        after = [ "docker.service" ];
        requires = [ "docker.service" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          WorkingDirectory = serviceDir;
          ExecStartPre = if envFileCommands != [ ] then envFileCommands else null;
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

      systemd.tmpfiles.rules = [
        "d ${serviceDir} 0755 root root -"
      ];

      # Auto-declare sops.secrets for all secretFile references
      sops.secrets = lib.genAttrs allSecretNames (_: { });
    };
}
