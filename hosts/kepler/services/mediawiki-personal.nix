# Personal wiki
# Runs in a NixOS container with SQLite backend.
# State is bind-mounted to /var/lib/mediawiki-personal on the host for backups.
#
# Access the container: machinectl shell wiki-personal
# Run maintenance:      machinectl shell wiki-personal /run/current-system/sw/bin/mediawiki-maintenance <script>.php
{ config, ... }:
let
  port = config.k.ports.mediawiki_personal_http;
in
{
  containers.wiki-personal = {
    autoStart = true;
    privateNetwork = false;

    bindMounts = {
      "/var/lib/mediawiki" = {
        hostPath = "/var/lib/mediawiki-personal";
        isReadOnly = false;
      };
      "/var/cache/mediawiki" = {
        hostPath = "/var/cache/mediawiki-personal";
        isReadOnly = false;
      };
      "/run/secrets/mediawiki-personal" = {
        hostPath = "/run/secrets/mediawiki-personal";
        isReadOnly = true;
      };
    };

    config = _: {
      services.mediawiki = {
        enable = true;
        name = "Kilian's Wiki";
        webserver = "nginx";
        nginx.hostName = "wiki.kilko.de";
        passwordFile = "/run/secrets/mediawiki-personal/admin_password";

        database = {
          type = "sqlite";
        };

        extensions = {
          ParserFunctions = null;
          VisualEditor = null;
        };

        extraConfig = ''
          # Private wiki — require login to read/edit
          $wgGroupPermissions['*']['read'] = false;
          $wgGroupPermissions['*']['edit'] = false;
          $wgGroupPermissions['*']['createaccount'] = false;

          $wgPingback = false;

          # Use bundled Parsoid for VisualEditor
          $wgVisualEditorParsoidAutoConfig = true;
        '';
      };

      services.nginx.virtualHosts."wiki.kilko.de".listen = [
        {
          addr = "0.0.0.0";
          inherit port;
        }
      ];

      networking.firewall.allowedTCPPorts = [ port ];

      system.stateVersion = "24.11";
    };
  };

  # Host-side: sops secret (decrypted to /run/secrets/mediawiki-personal/admin_password)
  sops.secrets."mediawiki-personal/admin_password" = {
    mode = "0444";
  };

  # Host-side: ensure bind-mount target directories exist
  systemd.tmpfiles.rules = [
    "d /var/lib/mediawiki-personal 0750 root root - -"
    "d /var/cache/mediawiki-personal 0750 root root - -"
  ];

  networking.firewall.allowedTCPPorts = [ port ];

  k.monitoring.systemdServices = [ "container@wiki-personal" ];
}
