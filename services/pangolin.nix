{
  config,
  lib,
  pkgs,
  ...
}:
let
  stateDir = "/var/lib/pangolin";
  envFile = "/etc/pangolin/env";
  cfg = config.services.pangolin;
  settingsFile = pkgs.writeText "pangolin.json" (builtins.toJSON cfg.settings);
  makeEnv = pkgs.writeScript "pangolin-env" ''
    #!/bin/sh
    set -eu
    ${lib.optionalString (cfg.envFile != null) ''
      # Copy provided env file into place
      cp ${cfg.envFile} ${envFile}
    ''}
  '';
  node = pkgs.nodejs_22; # runtime for next start
  runScript = pkgs.writeShellScript "pangolin-run" ''
    set -e
    cd ${pkgs.fosrl-pangolin}
    export NODE_ENV=production
    export PORT=80
    export HTTPS_PORT=443
    export PANGOLIN_DATA_DIR=${stateDir}
    export PANGOLIN_DB=${stateDir}/pangolin.sqlite
    export PANGOLIN_CONFIG=${settingsFile}
    if [ -f ${envFile} ]; then
      set -a
      . ${envFile}
      set +a
    fi
    exec ${node}/bin/node server.js
  '';
in
{
  options.services.pangolin = with lib; {
    enable = mkEnableOption "Pangolin reverse proxy";
    envFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Optional environment file with secrets and settings (KEY=VALUE)";
    };
    settings = mkOption {
      type = types.attrs;
      default = {
        host = "0.0.0.0";
        # Pangolin acts as reverse proxy on standard HTTP/HTTPS ports
      };
      description = "JSON settings passed to Pangolin";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.pangolin = {
      description = "Pangolin";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      environment = {
        NODE_ENV = "production";
      };
      serviceConfig = {
        Type = "simple";
        User = "pangolin";
        Group = "pangolin";
        ExecStartPre = makeEnv;
        ExecStart = runScript;
        Restart = "on-failure";
        WorkingDirectory = pkgs.fosrl-pangolin;
        StateDirectory = "pangolin";
        # Allow binding to ports 80/443
        AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
        CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
        # hardening
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        NoNewPrivileges = false; # Needed for capabilities
      };
    };

    users.users.pangolin = {
      isSystemUser = true;
      group = "pangolin";
      home = stateDir;
    };
    users.groups.pangolin = { };

    networking.firewall.allowedTCPPorts = [
      80
      443
    ];
  };
}
