{ config, ... }:
{
  services.paperless = {
    enable = true;

    port = config.k.ports.paperless_http;
    address = "0.0.0.0";
    domain = "http://localhost:${toString config.k.ports.paperless_http}";

    dataDir = "/var/lib/paperless";
    consumptionDir = "/var/lib/paperless/consume";
    mediaDir = "/var/lib/paperless/media";

    # TODO: passwordFile vs secretKey?
    passwordFile = config.sops.secrets."paperless/secret_key".path;

    settings = {
      PAPERLESS_OCR_LANGUAGE = "deu";
      PAPERLESS_TIME_ZONE = config.time.timeZone;
      PAPERLESS_ADMIN_USER = "admin";

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

  networking.firewall.allowedTCPPorts = [ config.k.ports.paperless_http ];
}
