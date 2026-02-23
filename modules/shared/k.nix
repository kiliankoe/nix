{ lib, ... }:
{
  options.k = {
    ports = lib.mkOption {
      type = lib.types.attrsOf lib.types.int;
      default = {
        changedetection_http = 8380;
        factorio_udp = 34197;
        forgejo_http = 8381;
        forgejo_ssh = 10022;
        freshrss_http = 8382;
        linkding_http = 8383;
        mato_http = 8384;
        paperless_http = 8385;
        rssbridge_http = 8386;
        uptime_kuma_http = 8387;
        wbbash_http = 8388;
        lehmuese-ics_http = 8389;
        foundry-vtt_http = 8390;
        cockpit_http = 8391;
        newsdiff_http = 8392;
        speedtest_tracker_http = 8393;
        lehmuese_http = 8394;
        prometheus_http = 8395;
        grafana_http = 8396;
        alertmanager_http = 8397;
        immich_http = 8398;
        plausible_http = 8399;
        fredy_http = 8400;
        rustypaste_http = 8401;
        actual_http = 8402;
        jobfinder_http = 8403;
        jobfinder_pocketbase_http = 8404;
        plex_http = 32400;
      };
      description = ''
        Central registry for service port assignments to avoid conflicts and
        keep them discoverable.
      '';
    };

    # Monitoring configuration - services register themselves here
    monitoring = {
      httpEndpoints = lib.mkOption {
        type = lib.types.listOf (
          lib.types.submodule {
            options = {
              name = lib.mkOption {
                type = lib.types.str;
                description = "Service name for display in alerts";
              };
              url = lib.mkOption {
                type = lib.types.str;
                description = "URL to probe";
              };
            };
          }
        );
        default = [ ];
        description = "HTTP endpoints to monitor via blackbox exporter";
      };

      dockerContainers = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Docker container names to monitor";
      };

      systemdServices = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Systemd service names to monitor for restarts/failures";
      };
    };

    # Backup configuration - services register their backup sources here
    backup = {
      dockerVolumes = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Docker volume name patterns to include in backups";
      };
    };
  };
}
