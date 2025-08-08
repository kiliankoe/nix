{ config, pkgs, ... }:
{
  services.paperless = {
    enable = true;

    port = 8382;
    address = "0.0.0.0";

    dataDir = "/var/lib/paperless";
    consumptionDir = "/var/lib/paperless/consume";
    mediaDir = "/var/lib/paperless/media";

    passwordFile = config.sops.secrets."paperless/secret_key".path;

    settings = {
      PAPERLESS_OCR_LANGUAGE = "deu";
      PAPERLESS_TIME_ZONE = config.time.timeZone;
      PAPERLESS_ADMIN_USER = "admin";
      PAPERLESS_URL = "http://localhost:8382";

      PAPERLESS_REDIS = "redis://localhost:6379";

      PAPERLESS_DBENGINE = "postgresql";
      PAPERLESS_DBNAME = "paperless";
      PAPERLESS_DBUSER = "paperless";
      PAPERLESS_DBHOST = "localhost";
      PAPERLESS_DBPORT = 5432;
    };
  };

  # PostgreSQL is configured globally in the host configuration

  services.redis.servers.paperless = {
    enable = true;
    port = 6379;
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/paperless/consume 0755 paperless paperless -"
    "d /var/lib/paperless/media 0755 paperless paperless -"
    "d /var/lib/paperless/export 0755 paperless paperless -"
  ];

  networking.firewall.allowedTCPPorts = [ 8382 ];
}
