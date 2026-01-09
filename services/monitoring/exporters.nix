# Prometheus exporters for kepler monitoring
{ config, pkgs, ... }:
{
  services.prometheus.exporters = {
    # System metrics: CPU, memory, disk, network
    node = {
      enable = true;
      enabledCollectors = [
        "systemd"
        "filesystem"
        "diskstats"
        "meminfo"
        "cpu"
        "loadavg"
        "netdev"
        "processes"
      ];
      extraFlags = [
        # Include /var/lib for service data monitoring
        "--collector.filesystem.mount-points-exclude=^/(dev|proc|sys|run|boot)($|/)"
      ];
    };

    # PostgreSQL metrics: connections, query stats, database sizes
    postgres = {
      enable = true;
      dataSourceName = "user=postgres host=/run/postgresql dbname=postgres";
      runAsLocalSuperUser = true;
    };

    # Redis metrics (used by paperless)
    redis = {
      enable = true;
      extraFlags = [
        "--redis.addr=redis://localhost:6379"
      ];
    };

    # Systemd service states and restart detection
    systemd = {
      enable = true;
      extraFlags = [
        "--systemd.collector.enable-restart-count"
      ];
    };

    # HTTP endpoint probes for application health checks
    blackbox = {
      enable = true;
      configFile = pkgs.writeText "blackbox.yml" (
        builtins.toJSON {
          modules = {
            http_2xx = {
              prober = "http";
              timeout = "5s";
              http = {
                valid_http_versions = [
                  "HTTP/1.1"
                  "HTTP/2.0"
                ];
                valid_status_codes = [ 200 ];
                method = "GET";
                follow_redirects = true;
              };
            };
            http_2xx_3xx = {
              prober = "http";
              timeout = "5s";
              http = {
                valid_http_versions = [
                  "HTTP/1.1"
                  "HTTP/2.0"
                ];
                valid_status_codes = [ ]; # Accept any 2xx or 3xx
                method = "GET";
                follow_redirects = true;
              };
            };
          };
        }
      );
    };
  };
}
