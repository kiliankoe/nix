# Family wiki
# Runs in a NixOS container with SQLite backend.
# State is bind-mounted to /var/lib/mediawiki-family on the host for backups.
#
# Access the container: machinectl shell wiki-family
# Run maintenance:      machinectl shell wiki-family /run/current-system/sw/bin/mediawiki-maintenance <script>.php
{ config, ... }:
let
  port = config.k.ports.mediawiki_family_http;
in
{
  containers.wiki-family = {
    autoStart = true;
    privateNetwork = false;

    bindMounts = {
      "/var/lib/mediawiki" = {
        hostPath = "/var/lib/mediawiki-family";
        isReadOnly = false;
      };
      "/var/cache/mediawiki" = {
        hostPath = "/var/cache/mediawiki-family";
        isReadOnly = false;
      };
      "/run/secrets/mediawiki-family" = {
        hostPath = "/run/secrets/mediawiki-family";
        isReadOnly = true;
      };
    };

    config = _: {
      services.mediawiki = {
        enable = true;
        name = "Költzsch Wiki";
        webserver = "nginx";
        nginx.hostName = "wiki.koeltzs.ch";
        passwordFile = "/run/secrets/mediawiki-family/admin_password";

        database = {
          type = "sqlite";
        };

        extensions = {
          ParserFunctions = null;
          VisualEditor = null;
          Cite = null;
        };

        extraConfig = ''
          # Private wiki — require login to read
          $wgGroupPermissions['*']['read'] = false;
          $wgGroupPermissions['*']['edit'] = false;
          $wgGroupPermissions['*']['createaccount'] = false;

          $wgLanguageCode = 'de';

          # Registered users (family members) can edit
          $wgGroupPermissions['user']['edit'] = true;

          $wgPingback = false;
          $wgJobRunRate = 1;

          # Use bundled Parsoid for VisualEditor
          $wgVisualEditorParsoidAutoConfig = true;

          $wgEnableUploads = true;
          $wgFileExtensions = array_merge( $wgFileExtensions, [
            'pdf', 'djvu',
            'mp3', 'ogg', 'flac', 'wav',
            'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'odt', 'ods', 'odp',
          ] );
          $wgMaxUploadSize = 50 * 1024 * 1024;
        '';

        poolConfig = {
          "pm" = "dynamic";
          "pm.max_children" = 32;
          "pm.start_servers" = 2;
          "pm.min_spare_servers" = 2;
          "pm.max_spare_servers" = 4;
          "pm.max_requests" = 500;
          "php_admin_value[upload_max_filesize]" = "50M";
          "php_admin_value[post_max_size]" = "50M";
        };
      };

      services.nginx.virtualHosts."wiki.koeltzs.ch".extraConfig = ''
        client_max_body_size 50M;
      '';
      services.nginx.virtualHosts."wiki.koeltzs.ch".locations."/".return = "302 /wiki/";
      services.nginx.virtualHosts."wiki.koeltzs.ch".listen = [
        {
          addr = "0.0.0.0";
          inherit port;
        }
      ];

      networking.firewall.allowedTCPPorts = [ port ];

      system.stateVersion = "24.11";
    };
  };

  # Host-side: sops secret (decrypted to /run/secrets/mediawiki-family/admin_password)
  sops.secrets."mediawiki-family/admin_password" = {
    mode = "0444";
  };

  # Host-side: ensure bind-mount target directories exist
  systemd.tmpfiles.rules = [
    "d /var/lib/mediawiki-family 0750 root root - -"
    "d /var/cache/mediawiki-family 0750 root root - -"
  ];

  networking.firewall.allowedTCPPorts = [ port ];

  k.monitoring.systemdServices = [ "container@wiki-family" ];
}
