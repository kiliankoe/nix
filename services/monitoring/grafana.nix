# Grafana with Prometheus datasource and pre-provisioned dashboards
{
  config,
  pkgs,
  ...
}:
let
  # Simple dashboard for kepler overview
  keplerDashboard = pkgs.writeText "kepler-dashboard.json" (
    builtins.toJSON {
      annotations.list = [ ];
      editable = true;
      fiscalYearStartMonth = 0;
      graphTooltip = 0;
      id = null;
      links = [ ];
      liveNow = false;
      panels = [
        {
          datasource = {
            type = "prometheus";
            uid = "prometheus";
          };
          fieldConfig = {
            defaults = {
              color.mode = "palette-classic";
              mappings = [ ];
              thresholds = {
                mode = "absolute";
                steps = [
                  {
                    color = "green";
                    value = null;
                  }
                  {
                    color = "yellow";
                    value = 70;
                  }
                  {
                    color = "red";
                    value = 85;
                  }
                ];
              };
              unit = "percent";
            };
            overrides = [ ];
          };
          gridPos = {
            h = 6;
            w = 6;
            x = 0;
            y = 0;
          };
          id = 1;
          options = {
            orientation = "auto";
            reduceOptions = {
              calcs = [ "lastNotNull" ];
              fields = "";
              values = false;
            };
            showThresholdLabels = false;
            showThresholdMarkers = true;
          };
          title = "Memory Usage";
          type = "gauge";
          targets = [
            {
              expr = "(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100";
              refId = "A";
            }
          ];
        }
        {
          datasource = {
            type = "prometheus";
            uid = "prometheus";
          };
          fieldConfig = {
            defaults = {
              color.mode = "palette-classic";
              mappings = [ ];
              thresholds = {
                mode = "absolute";
                steps = [
                  {
                    color = "green";
                    value = null;
                  }
                  {
                    color = "yellow";
                    value = 70;
                  }
                  {
                    color = "red";
                    value = 85;
                  }
                ];
              };
              unit = "percent";
            };
            overrides = [ ];
          };
          gridPos = {
            h = 6;
            w = 6;
            x = 6;
            y = 0;
          };
          id = 2;
          options = {
            orientation = "auto";
            reduceOptions = {
              calcs = [ "lastNotNull" ];
              fields = "";
              values = false;
            };
            showThresholdLabels = false;
            showThresholdMarkers = true;
          };
          title = "Disk Usage (/)";
          type = "gauge";
          targets = [
            {
              expr = "(1 - (node_filesystem_avail_bytes{mountpoint=\"/\"} / node_filesystem_size_bytes{mountpoint=\"/\"})) * 100";
              refId = "A";
            }
          ];
        }
        {
          datasource = {
            type = "prometheus";
            uid = "prometheus";
          };
          fieldConfig = {
            defaults = {
              color.mode = "palette-classic";
              mappings = [ ];
              thresholds = {
                mode = "absolute";
                steps = [
                  {
                    color = "green";
                    value = null;
                  }
                  {
                    color = "yellow";
                    value = 2;
                  }
                  {
                    color = "red";
                    value = 4;
                  }
                ];
              };
              unit = "short";
            };
            overrides = [ ];
          };
          gridPos = {
            h = 6;
            w = 6;
            x = 12;
            y = 0;
          };
          id = 3;
          options = {
            orientation = "auto";
            reduceOptions = {
              calcs = [ "lastNotNull" ];
              fields = "";
              values = false;
            };
            showThresholdLabels = false;
            showThresholdMarkers = true;
          };
          title = "Load (5m)";
          type = "gauge";
          targets = [
            {
              expr = "node_load5";
              refId = "A";
            }
          ];
        }
        {
          datasource = {
            type = "prometheus";
            uid = "prometheus";
          };
          fieldConfig = {
            defaults = {
              color.mode = "palette-classic";
              mappings = [ ];
              thresholds = {
                mode = "absolute";
                steps = [
                  {
                    color = "green";
                    value = null;
                  }
                ];
              };
              unit = "s";
            };
            overrides = [ ];
          };
          gridPos = {
            h = 6;
            w = 6;
            x = 18;
            y = 0;
          };
          id = 4;
          options = {
            colorMode = "value";
            graphMode = "area";
            justifyMode = "auto";
            orientation = "auto";
            reduceOptions = {
              calcs = [ "lastNotNull" ];
              fields = "";
              values = false;
            };
            textMode = "auto";
          };
          title = "Uptime";
          type = "stat";
          targets = [
            {
              expr = "node_time_seconds - node_boot_time_seconds";
              refId = "A";
            }
          ];
        }
        {
          datasource = {
            type = "prometheus";
            uid = "prometheus";
          };
          fieldConfig = {
            defaults = {
              color.mode = "palette-classic";
              custom = {
                axisBorderShow = false;
                axisCenteredZero = false;
                axisColorMode = "text";
                axisLabel = "";
                axisPlacement = "auto";
                barAlignment = 0;
                drawStyle = "line";
                fillOpacity = 10;
                gradientMode = "none";
                hideFrom = {
                  legend = false;
                  tooltip = false;
                  viz = false;
                };
                insertNulls = false;
                lineInterpolation = "smooth";
                lineWidth = 1;
                pointSize = 5;
                scaleDistribution.type = "linear";
                showPoints = "never";
                spanNulls = false;
                stacking = {
                  group = "A";
                  mode = "none";
                };
                thresholdsStyle.mode = "off";
              };
              mappings = [ ];
              thresholds = {
                mode = "absolute";
                steps = [
                  {
                    color = "green";
                    value = null;
                  }
                ];
              };
              unit = "percent";
            };
            overrides = [ ];
          };
          gridPos = {
            h = 8;
            w = 12;
            x = 0;
            y = 6;
          };
          id = 5;
          options = {
            legend = {
              calcs = [ ];
              displayMode = "list";
              placement = "bottom";
              showLegend = true;
            };
            tooltip = {
              mode = "single";
              sort = "none";
            };
          };
          title = "Memory Over Time";
          type = "timeseries";
          targets = [
            {
              expr = "(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100";
              legendFormat = "Memory %";
              refId = "A";
            }
          ];
        }
        {
          datasource = {
            type = "prometheus";
            uid = "prometheus";
          };
          fieldConfig = {
            defaults = {
              color.mode = "palette-classic";
              custom = {
                axisBorderShow = false;
                axisCenteredZero = false;
                axisColorMode = "text";
                axisLabel = "";
                axisPlacement = "auto";
                barAlignment = 0;
                drawStyle = "line";
                fillOpacity = 10;
                gradientMode = "none";
                hideFrom = {
                  legend = false;
                  tooltip = false;
                  viz = false;
                };
                insertNulls = false;
                lineInterpolation = "smooth";
                lineWidth = 1;
                pointSize = 5;
                scaleDistribution.type = "linear";
                showPoints = "never";
                spanNulls = false;
                stacking = {
                  group = "A";
                  mode = "none";
                };
                thresholdsStyle.mode = "off";
              };
              mappings = [ ];
              thresholds = {
                mode = "absolute";
                steps = [
                  {
                    color = "green";
                    value = null;
                  }
                ];
              };
              unit = "short";
            };
            overrides = [ ];
          };
          gridPos = {
            h = 8;
            w = 12;
            x = 12;
            y = 6;
          };
          id = 6;
          options = {
            legend = {
              calcs = [ ];
              displayMode = "list";
              placement = "bottom";
              showLegend = true;
            };
            tooltip = {
              mode = "single";
              sort = "none";
            };
          };
          title = "Load Average";
          type = "timeseries";
          targets = [
            {
              expr = "node_load1";
              legendFormat = "1m";
              refId = "A";
            }
            {
              expr = "node_load5";
              legendFormat = "5m";
              refId = "B";
            }
            {
              expr = "node_load15";
              legendFormat = "15m";
              refId = "C";
            }
          ];
        }
        {
          datasource = {
            type = "prometheus";
            uid = "prometheus";
          };
          fieldConfig = {
            defaults = {
              color.mode = "thresholds";
              mappings = [
                {
                  options = {
                    "0" = {
                      color = "red";
                      index = 1;
                      text = "DOWN";
                    };
                    "1" = {
                      color = "green";
                      index = 0;
                      text = "UP";
                    };
                  };
                  type = "value";
                }
              ];
              thresholds = {
                mode = "absolute";
                steps = [
                  {
                    color = "red";
                    value = null;
                  }
                  {
                    color = "green";
                    value = 1;
                  }
                ];
              };
            };
            overrides = [ ];
          };
          gridPos = {
            h = 8;
            w = 24;
            x = 0;
            y = 14;
          };
          id = 7;
          options = {
            colorMode = "background";
            graphMode = "none";
            justifyMode = "auto";
            orientation = "auto";
            reduceOptions = {
              calcs = [ "lastNotNull" ];
              fields = "";
              values = false;
            };
            textMode = "auto";
          };
          title = "Service Health (HTTP Probes)";
          type = "stat";
          targets = [
            {
              expr = "probe_success{job=\"blackbox-http\"}";
              legendFormat = "{{ instance }}";
              refId = "A";
            }
          ];
        }
        {
          datasource = {
            type = "prometheus";
            uid = "prometheus";
          };
          fieldConfig = {
            defaults = {
              color.mode = "palette-classic";
              mappings = [ ];
              thresholds = {
                mode = "absolute";
                steps = [
                  {
                    color = "green";
                    value = null;
                  }
                ];
              };
              unit = "short";
            };
            overrides = [ ];
          };
          gridPos = {
            h = 6;
            w = 12;
            x = 0;
            y = 22;
          };
          id = 8;
          options = {
            colorMode = "value";
            graphMode = "area";
            justifyMode = "auto";
            orientation = "auto";
            reduceOptions = {
              calcs = [ "lastNotNull" ];
              fields = "";
              values = false;
            };
            textMode = "auto";
          };
          title = "PostgreSQL Connections";
          type = "stat";
          targets = [
            {
              expr = "pg_stat_activity_count";
              refId = "A";
            }
          ];
        }
        {
          datasource = {
            type = "prometheus";
            uid = "prometheus";
          };
          fieldConfig = {
            defaults = {
              color.mode = "thresholds";
              mappings = [
                {
                  options = {
                    "0" = {
                      color = "red";
                      index = 1;
                      text = "DOWN";
                    };
                    "1" = {
                      color = "green";
                      index = 0;
                      text = "UP";
                    };
                  };
                  type = "value";
                }
              ];
              thresholds = {
                mode = "absolute";
                steps = [
                  {
                    color = "red";
                    value = null;
                  }
                  {
                    color = "green";
                    value = 1;
                  }
                ];
              };
            };
            overrides = [ ];
          };
          gridPos = {
            h = 6;
            w = 12;
            x = 12;
            y = 22;
          };
          id = 9;
          options = {
            colorMode = "background";
            graphMode = "none";
            justifyMode = "auto";
            orientation = "auto";
            reduceOptions = {
              calcs = [ "lastNotNull" ];
              fields = "";
              values = false;
            };
            textMode = "auto";
          };
          title = "Redis";
          type = "stat";
          targets = [
            {
              expr = "redis_up";
              legendFormat = "Redis";
              refId = "A";
            }
          ];
        }
      ];
      refresh = "30s";
      schemaVersion = 39;
      tags = [
        "kepler"
        "overview"
      ];
      templating.list = [ ];
      time = {
        from = "now-1h";
        to = "now";
      };
      timepicker = { };
      timezone = "browser";
      title = "Kepler Overview";
      uid = "kepler-overview";
      version = 1;
    }
  );

  dashboardsDir = pkgs.runCommand "grafana-dashboards" { } ''
    mkdir -p $out
    cp ${keplerDashboard} $out/kepler-overview.json
  '';
in
{
  services.grafana = {
    enable = true;

    settings = {
      server = {
        http_port = config.k.ports.grafana_http;
        http_addr = "0.0.0.0";
        domain = "kepler";
        root_url = "http://kepler:${toString config.k.ports.grafana_http}/";
      };

      security = {
        admin_user = "admin";
        admin_password = "$__file{/run/secrets/monitoring/grafana_admin_password}";
        # Allow embedding in iframes (useful for status pages)
        allow_embedding = true;
      };

      # Disable analytics/telemetry
      analytics = {
        reporting_enabled = false;
        check_for_updates = false;
      };

      # Disable user signup
      users = {
        allow_sign_up = false;
        allow_org_create = false;
      };
    };

    # Provision Prometheus datasource
    provision = {
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          url = "http://localhost:${toString config.k.ports.prometheus_http}";
          uid = "prometheus";
          isDefault = true;
          editable = false;
        }
      ];

      # Pre-provision dashboards
      dashboards.settings.providers = [
        {
          name = "kepler";
          orgId = 1;
          type = "file";
          disableDeletion = false;
          editable = true;
          options = {
            path = dashboardsDir;
          };
        }
      ];
    };
  };

  # Declare secrets for grafana
  sops.secrets."monitoring/grafana_admin_password" = {
    owner = "grafana";
  };
}
