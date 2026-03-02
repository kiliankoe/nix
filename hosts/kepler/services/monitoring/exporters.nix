# Prometheus exporters for kepler monitoring
{ pkgs, ... }:
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
                # Empty array means "only 2xx"
                valid_status_codes = [
                  200
                  201
                  204
                  301
                  302
                  303
                  304
                  307
                  308
                ];
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
