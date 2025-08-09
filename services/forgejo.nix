{ config, pkgs, ... }:
{
  services.forgejo = {
    enable = true;

    database = {
      type = "postgres";
      createDatabase = true;
      user = "forgejo";
      name = "forgejo";
      passwordFile = config.sops.secrets."forgejo/postgres_password".path;
    };

    settings = {
      server = {
        HTTP_PORT = config.k.ports.forgejo_http;
        SSH_PORT = config.k.ports.forgejo_ssh;
        DOMAIN = "localhost";
        ROOT_URL = "https://git.kilko.de";
      };

      service = {
        DEFAULT_UI_LOCATION = "Europe/Berlin";
      };

      security = {
        INSTALL_LOCK = true;
      };
    };
  };

  # PostgreSQL is configured globally in the host configuration

  networking.firewall.allowedTCPPorts = [
    config.k.ports.forgejo_http
    config.k.ports.forgejo_ssh
  ];
}
