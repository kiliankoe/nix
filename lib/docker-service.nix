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
  # monitoring: Optional monitoring configuration
  #   enable: Whether to register for monitoring (default: true, set to false for infra containers)
  #   containers: List of container names to monitor (auto-detected from compose if not specified)
  #   httpEndpoint: Optional { name, url } for HTTP endpoint monitoring
  # backupVolumes: Optional list of Docker volume name patterns to include in backups
  # auto_update: Whether to enable watchtower auto-updates for all containers (default: false)
  mkDockerComposeService =
    {
      serviceName,
      compose,
      extraFiles ? { },
      environment ? { },
      monitoring ? { },
      backupVolumes ? [ ],
      auto_update ? false,
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

      # Watchtower auto-update label
      watchtowerLabel = "com.centurylinklabs.watchtower.enable=true";

      # Transform compose.services to add watchtower label when auto_update is true
      servicesWithAutoUpdate =
        if auto_update && compose ? services then
          lib.mapAttrs (
            _: svcConfig:
            svcConfig
            // {
              labels = (svcConfig.labels or [ ]) ++ [ watchtowerLabel ];
            }
          ) compose.services
        else
          compose.services or { };

      # Use the transformed compose
      finalCompose = compose // {
        services = servicesWithAutoUpdate;
      };

      composeFile = yamlFormat.generate "${serviceName}-compose.yml" finalCompose;

      # Extract container names from compose services
      # Uses container_name if specified, otherwise the service name
      autoContainerNames =
        if compose ? services then
          lib.mapAttrsToList (svcName: svcConfig: svcConfig.container_name or svcName) compose.services
        else
          [ ];

      # Use explicitly specified containers or auto-detected ones
      monitoredContainers = monitoring.containers or autoContainerNames;

      # Check if monitoring is enabled (default: true)
      monitoringEnabled = monitoring.enable or true;
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

      # Register containers and endpoints for monitoring (if enabled)
      k = {
        monitoring = lib.mkIf monitoringEnabled {
          dockerContainers = monitoredContainers;
          httpEndpoints = lib.optional (monitoring ? httpEndpoint) monitoring.httpEndpoint;
          systemdServices = [ serviceName ];
        };
        backup.dockerVolumes = backupVolumes;
      };
    };
}
