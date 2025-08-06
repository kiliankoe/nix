{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix

    ../../modules/shared/base.nix
    # ../../modules/shared/tmux.nix
    ../../modules/shared/zsh.nix
    ../../modules/shared/sops.nix

    ../../modules/nixos/base.nix

    ./packages.nix

    ../../services/changedetection.nix
    ../../services/factorio.nix
    ../../services/forgejo.nix
    ../../services/freshrss.nix
    ../../services/lehmuese-ics.nix
    ../../services/linkding.nix
    ../../services/mato.nix
    ../../services/paperless.nix
    ../../services/swiftdebot.nix
    ../../services/watchtower.nix
    ../../services/wbbash.nix
  ];

  # Networking
  networking.hostName = "kepler";

  # Service secrets
  sops.secrets = {
    "linkding/superuser_name" = { };
    "linkding/superuser_password" = { };
    "paperless/secret_key" = { };
    "freshrss/rssbridge_auth_user" = { };
    "freshrss/rssbridge_auth_hash" = { };
    "swiftdebot/discord_token" = { };
    "swiftdebot/discord_app_id" = { };
    "swiftdebot/discord_logs_webhook_url" = { };
    "swiftdebot/kagi_api_token" = { };
    "swiftdebot/openai_api_token" = { };
    "wbbash/miniqdb_name" = { };
    "wbbash/allowed_domains" = { };
    "wbbash/nothing_to_see_here_text" = { };
    "wbbash/login_button_text" = { };
    "wbbash/nextauth_secret" = { };
    "wbbash/email_server_host" = { };
    "wbbash/email_server_port" = { };
    "wbbash/email_server_user" = { };
    "wbbash/email_server_password" = { };
    "wbbash/email_from" = { };
    "lehmuese_ics/url" = { };
    "mato/my_email" = { };
    "mato/smtp_host" = { };
    "mato/smtp_from" = { };
    "mato/smtp_user" = { };
    "mato/smtp_pass" = { };
    "mato/catfact_slack_webhook" = { };
  };

  # Disable power management (server)
  powerManagement.enable = false;
  systemd = {
    targets = {
      sleep = {
        enable = false;
        unitConfig.DefaultDependencies = "no";
      };
      suspend = {
        enable = false;
        unitConfig.DefaultDependencies = "no";
      };
      hibernate = {
        enable = false;
        unitConfig.DefaultDependencies = "no";
      };
      "hybrid-sleep" = {
        enable = false;
        unitConfig.DefaultDependencies = "no";
      };
    };
  };

  # WebDAV mount for Tailscale
  services.davfs2.enable = true;
  fileSystems."/mnt/tailscale" = {
    device = "none";
    fsType = "tmpfs";
    options = [ "defaults" ];
  };

  systemd.mounts = [
    {
      enable = true;
      description = "Tailscale Drive WebDAV mount";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      what = "http://100.100.100.100:8080";
      where = "/mnt/tailscale";
      options = "uid=1000,gid=100,file_mode=0664,dir_mode=0775,_netdev";
      type = "davfs";
      mountConfig.TimeoutSec = 30;
    }
  ];

  services.cron = {
    enable = true;
    systemCronJobs = [
      # "0 4 * * 1      kilian    sudo rsync -av --progress html /mnt/tailscale/kiliankoe.github/marvin/backups/nextcloud/"
    ];
  };

}
