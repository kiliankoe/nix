# Prometheus server with scrape configs and alert rules
{
  config,
  pkgs,
  lib,
  ...
}:
let
  # Services to probe via blackbox exporter
  httpTargets = [
    {
      name = "paperless";
      url = "http://localhost:${toString config.k.ports.paperless_http}/api/";
    }
    {
      name = "freshrss";
      url = "http://localhost:${toString config.k.ports.freshrss_http}/";
    }
    {
      name = "linkding";
      url = "http://localhost:${toString config.k.ports.linkding_http}/";
    }
    {
      name = "mato";
      url = "http://localhost:${toString config.k.ports.mato_http}/";
    }
    {
      name = "changedetection";
      url = "http://localhost:${toString config.k.ports.changedetection_http}/";
    }
    {
      name = "uptime-kuma";
      url = "http://localhost:${toString config.k.ports.uptime_kuma_http}/";
    }
    {
      name = "wbbash";
      url = "http://localhost:${toString config.k.ports.wbbash_http}/";
    }
  ];

  # Docker containers to monitor for restart/down detection
  dockerContainers = [
    "linkding"
    "mato"
    "changedetection"
    "foundry"
    "wbbash"
    "lehmuese"
    "newsdiff"
  ];

  alertRules = pkgs.writeText "alert-rules.yml" (
    builtins.toJSON {
      groups = [
        {
          name = "kepler-system";
          rules = [
            # Disk space alerts
            {
              alert = "DiskSpaceLow";
              expr = ''(node_filesystem_avail_bytes{fstype!~"tmpfs|overlay"} / node_filesystem_size_bytes{fstype!~"tmpfs|overlay"}) * 100 < 15'';
              for = "5m";
              labels.severity = "warning";
              annotations = {
                summary = "Disk space below 15% on {{ $labels.mountpoint }}";
                description = "{{ $labels.mountpoint }} has {{ printf \"%.1f\" $value }}% free space remaining.";
              };
            }
            {
              alert = "DiskSpaceCritical";
              expr = ''(node_filesystem_avail_bytes{fstype!~"tmpfs|overlay"} / node_filesystem_size_bytes{fstype!~"tmpfs|overlay"}) * 100 < 5'';
              for = "2m";
              labels.severity = "critical";
              annotations = {
                summary = "Disk space critically low on {{ $labels.mountpoint }}";
                description = "{{ $labels.mountpoint }} has only {{ printf \"%.1f\" $value }}% free space!";
              };
            }

            # Memory pressure
            {
              alert = "MemoryPressure";
              expr = "(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 85";
              for = "5m";
              labels.severity = "warning";
              annotations = {
                summary = "Memory usage above 85%";
                description = "System memory usage is at {{ printf \"%.1f\" $value }}%.";
              };
            }
            {
              alert = "MemoryCritical";
              expr = "(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 95";
              for = "2m";
              labels.severity = "critical";
              annotations = {
                summary = "Memory usage critical (>95%)";
                description = "System memory usage is at {{ printf \"%.1f\" $value }}%. Services may be killed by OOM.";
              };
            }

            # High CPU load
            {
              alert = "HighCPULoad";
              expr = "node_load5 > 4";
              for = "10m";
              labels.severity = "warning";
              annotations = {
                summary = "High CPU load (5min avg > 4)";
                description = "5-minute load average is {{ printf \"%.2f\" $value }}.";
              };
            }
          ];
        }
        {
          name = "kepler-services";
          rules = [
            # Service restart detection
            {
              alert = "ServiceRestarted";
              expr = ''increase(systemd_unit_start_time_seconds{name=~"(paperless|freshrss|linkding|mato|changedetection|uptime-kuma|wbbash|foundry-vtt|newsdiff|prometheus|grafana|alertmanager).*\\.service"}[10m]) > 0'';
              for = "0m";
              labels.severity = "warning";
              annotations = {
                summary = "Service {{ $labels.name }} restarted";
                description = "The service {{ $labels.name }} has restarted in the last 10 minutes.";
              };
            }

            # Systemd service failed
            {
              alert = "ServiceFailed";
              expr = ''systemd_unit_state{name=~"(paperless|freshrss|linkding|mato|changedetection|uptime-kuma|wbbash|foundry-vtt|newsdiff).*\\.service",state="failed"} == 1'';
              for = "1m";
              labels.severity = "critical";
              annotations = {
                summary = "Service {{ $labels.name }} failed";
                description = "The systemd service {{ $labels.name }} is in failed state.";
              };
            }

            # HTTP endpoint down
            {
              alert = "EndpointDown";
              expr = "probe_success{job=\"blackbox-http\"} == 0";
              for = "2m";
              labels.severity = "critical";
              annotations = {
                summary = "HTTP endpoint down: {{ $labels.instance }}";
                description = "The endpoint {{ $labels.instance }} has been unreachable for 2+ minutes.";
              };
            }
          ];
        }
        {
          name = "kepler-database";
          rules = [
            # PostgreSQL connection pool
            {
              alert = "PostgresConnectionsHigh";
              expr = "pg_stat_activity_count > 80";
              for = "5m";
              labels.severity = "warning";
              annotations = {
                summary = "PostgreSQL connections high (>80)";
                description = "PostgreSQL has {{ $value }} active connections.";
              };
            }

            # PostgreSQL connection pool critical
            {
              alert = "PostgresConnectionsCritical";
              expr = "pg_stat_activity_count > 95";
              for = "2m";
              labels.severity = "critical";
              annotations = {
                summary = "PostgreSQL connections critical (>95)";
                description = "PostgreSQL has {{ $value }} active connections, approaching max.";
              };
            }

            # Redis down
            {
              alert = "RedisDown";
              expr = "redis_up == 0";
              for = "2m";
              labels.severity = "critical";
              annotations = {
                summary = "Redis is down";
                description = "Redis server is not responding. Paperless may be affected.";
              };
            }
          ];
        }
        {
          name = "kepler-containers";
          rules = [
            # Container not running
            {
              alert = "ContainerDown";
              expr = ''absent(container_last_seen{name=~"${lib.concatStringsSep "|" dockerContainers}"}) or (time() - container_last_seen{name=~"${lib.concatStringsSep "|" dockerContainers}"}) > 300'';
              for = "5m";
              labels.severity = "critical";
              annotations = {
                summary = "Container {{ $labels.name }} is down";
                description = "Docker container {{ $labels.name }} has been missing for 5+ minutes.";
              };
            }

            # Container high memory
            {
              alert = "ContainerHighMemory";
              expr = "(container_memory_usage_bytes / container_spec_memory_limit_bytes) * 100 > 90";
              for = "5m";
              labels.severity = "warning";
              annotations = {
                summary = "Container {{ $labels.name }} memory usage >90%";
                description = "Container {{ $labels.name }} is using {{ printf \"%.1f\" $value }}% of its memory limit.";
              };
            }
          ];
        }
      ];
    }
  );
in
{
  services.prometheus = {
    enable = true;
    port = config.k.ports.prometheus_http;
    listenAddress = "0.0.0.0";

    # 30 days retention
    extraFlags = [
      "--storage.tsdb.retention.time=30d"
      "--web.enable-lifecycle"
    ];

    # Alert rules
    ruleFiles = [ alertRules ];

    # AlertManager integration
    alertmanagers = [
      {
        static_configs = [
          { targets = [ "localhost:${toString config.k.ports.alertmanager_http}" ]; }
        ];
      }
    ];

    scrapeConfigs = [
      # Node exporter (system metrics)
      {
        job_name = "node";
        static_configs = [
          {
            targets = [ "localhost:9100" ];
            labels = {
              instance = "kepler";
            };
          }
        ];
      }

      # PostgreSQL exporter
      {
        job_name = "postgres";
        static_configs = [
          {
            targets = [ "localhost:9187" ];
            labels = {
              instance = "kepler";
            };
          }
        ];
      }

      # Redis exporter
      {
        job_name = "redis";
        static_configs = [
          {
            targets = [ "localhost:9121" ];
            labels = {
              instance = "kepler";
            };
          }
        ];
      }

      # Systemd exporter
      {
        job_name = "systemd";
        static_configs = [
          {
            targets = [ "localhost:9558" ];
            labels = {
              instance = "kepler";
            };
          }
        ];
      }

      # cAdvisor (Docker container metrics)
      {
        job_name = "cadvisor";
        static_configs = [
          {
            targets = [ "localhost:8080" ];
            labels = {
              instance = "kepler";
            };
          }
        ];
      }

      # Blackbox HTTP probes
      {
        job_name = "blackbox-http";
        metrics_path = "/probe";
        params = {
          module = [ "http_2xx_3xx" ];
        };
        static_configs = [
          {
            targets = map (t: t.url) httpTargets;
          }
        ];
        relabel_configs = [
          {
            source_labels = [ "__address__" ];
            target_label = "__param_target";
          }
          {
            source_labels = [ "__param_target" ];
            target_label = "instance";
          }
          {
            target_label = "__address__";
            replacement = "localhost:9115";
          }
        ];
      }

      # Prometheus self-monitoring
      {
        job_name = "prometheus";
        static_configs = [
          { targets = [ "localhost:${toString config.k.ports.prometheus_http}" ]; }
        ];
      }
    ];
  };
}
