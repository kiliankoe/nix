{ pkgs, inputs, ... }:
{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  networking.networkmanager.enable = true;

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

  users.users.kilian = {
    isNormalUser = true;
    description = "Kilian";
    shell = pkgs.zsh;
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
    ];
    openssh.authorizedKeys.keys = [
      # Just in case
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINtIFrxGQrlRGyBqA6V2z7dywl0Q5b1Bg/9mJdQsv8bI me@kilian.io"
    ]
    ++ (
      # Additional keys fetched from GitHub
      pkgs.lib.filter (key: key != "") (pkgs.lib.splitString "\n" (builtins.readFile inputs.ssh-keys))
    );
  };

  home-manager.users.kilian = {
    imports = [
      ../../home/common.nix
      ../../home/nixos.nix
    ];
  };

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

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
    knownHosts = {
      "github.com" = {
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
      };
    };
  };
  services.tailscale.enable = true;
  virtualisation.docker.enable = true;

  programs.zsh.enable = true;

  # Used for backwards compatibility, don't touch.
  system.stateVersion = "24.11";
}
