{ pkgs, lib }:

let
  yamlFormat = pkgs.formats.yaml { };

  # Backup configuration using sops secrets (paths are /run/secrets/<name>)
  backupConfig = {
    serverFile = "/run/secrets/kepler_backup/server";
    usernameFile = "/run/secrets/kepler_backup/username";
    passwordFile = "/run/secrets/kepler_backup/password";
    basePath = "/backups";
    schedule = "0 4 * * *"; # Daily at 4 AM
  };
in
{
  # Creates a standardized Docker Compose service
  # serviceName: Name of the service
  # compose: Attrset representing the docker-compose.yml structure
  # extraFiles: Optional attrset of additional files to copy
  # environment: Optional attrset of service-scoped environment variables and secrets
  #   Format: { serviceName = { VAR = value; SECRET = { secretFile = "/path"; }; }; }
  # volumesToBackup: Optional list of volume names to backup with docker-volume-backup
  #   Uses SFTP backup to server configured in sops secrets (kepler_backup/*)
  mkDockerComposeService =
    {
      serviceName,
      compose,
      extraFiles ? { },
      environment ? { },
      volumesToBackup ? [ ],
    }:
    let
      serviceDir = "/etc/docker-compose/${serviceName}";

      # Create environment file scripts for each service
      envScripts = builtins.mapAttrs (
        svcName: envVars:
        pkgs.writeScript "${serviceName}-${svcName}-env" ''
          #!/bin/sh
          ${builtins.concatStringsSep "\n" (
            builtins.attrValues (
              builtins.mapAttrs (
                name: value:
                if builtins.isAttrs value && value ? secretFile then
                  "echo \"${name}=$(cat ${value.secretFile})\""
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

      # Create backup environment file script if volumes are specified
      backupEnvScript =
        if volumesToBackup != [ ] then
          pkgs.writeScript "${serviceName}-backup-env" ''
            #!/bin/sh
            echo "BACKUP_CRON_EXPRESSION=${backupConfig.schedule}"
            echo "SSH_HOST_NAME=$(cat ${backupConfig.serverFile})"
            echo "SSH_USER=$(cat ${backupConfig.usernameFile})"
            echo "SSH_PASSWORD=$(cat ${backupConfig.passwordFile})"
            echo "SSH_REMOTE_PATH=${backupConfig.basePath}/${serviceName}"
          ''
        else
          null;

      # Add backup env file command if needed
      backupEnvCommand =
        if backupEnvScript != null then
          [ "${pkgs.bash}/bin/bash -c '${backupEnvScript} > ${serviceDir}/backup.env'" ]
        else
          [ ];

      # Backup service definition
      backupService =
        if volumesToBackup != [ ] then
          {
            services.backup = {
              image = "offen/docker-volume-backup:v2";
              restart = "always";
              env_file = [ "./backup.env" ];
              volumes = [
                "/var/run/docker.sock:/var/run/docker.sock:ro"
              ]
              ++ map (vol: "${vol}:/backup/${vol}:ro") volumesToBackup;
            };
          }
        else
          { };

      # Merge compose config with backup service
      finalCompose = lib.recursiveUpdate compose backupService;
      composeFile = yamlFormat.generate "${serviceName}-compose.yml" finalCompose;
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

        serviceConfig =
          let
            allEnvCommands = envFileCommands ++ backupEnvCommand;
          in
          {
            Type = "oneshot";
            RemainAfterExit = true;
            WorkingDirectory = serviceDir;
            ExecStartPre = if allEnvCommands != [ ] then allEnvCommands else null;
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
    };
}
