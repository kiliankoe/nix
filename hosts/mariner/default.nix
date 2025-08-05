{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/shared/dev-tools.nix
    ../../modules/shared/zsh.nix
    ../../modules/nixos/forgejo-service.nix
    ../../modules/nixos/mato-service.nix
    ../../modules/nixos/watchtower-service.nix
    ../../packages/mariner-packages.nix
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking
  networking.hostName = "mariner";
  networking.networkmanager.enable = true;

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

  # Time zone and locale
  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };

  # Desktop environment
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Audio
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Mouse settings
  services.libinput.mouse.naturalScrolling = true;

  # User configuration
  users.users.kilian = {
    isNormalUser = true;
    description = "Kilian";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    packages = with pkgs; [
      kdePackages.kate
    ];
  };

  # Sudo configuration
  security.sudo.extraRules = [
    {
      users = [ "kilian" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  # Auto-login
  services.displayManager = {
    autoLogin.enable = true;
    autoLogin.user = "kilian";
  };

  # Services
  programs.firefox.enable = true;
  services.printing.enable = true;
  services.openssh.enable = true;
  services.tailscale.enable = true;
  virtualisation.docker.enable = true;

  # Cron job
  services.cron = {
    enable = true;
    systemCronJobs = [
      "0 4 * * 1      kilian    sudo rsync -av --progress html /mnt/tailscale/kiliankoe.github/marvin/backups/nextcloud/"
    ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # System version
  system.stateVersion = "24.11";
}