{ config, pkgs, lib, modulesPath, ... }:
{
  imports = [
    # Include the default NixOS ISO modules
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"

    # Include your Mariner configuration (but skip hardware-configuration.nix)
    ../modules/nixos/base.nix
    ../modules/shared/base.nix
    ../modules/shared/zsh.nix
    ../modules/nixos/forgejo-service.nix
    ../modules/nixos/mato-service.nix
    ../modules/nixos/watchtower-service.nix
    ../hosts/mariner/packages.nix
  ];

  # ISO-specific settings
  networking.hostName = "mariner-installer";

  # Include your services but don't auto-start them
  systemd.services = {
    docker-compose-forgejo.wantedBy = lib.mkForce [];
    docker-compose-mato.wantedBy = lib.mkForce [];
    docker-compose-watchtower.wantedBy = lib.mkForce [];
  };

  # Disable power management for the ISO
  powerManagement.enable = false;
  systemd = {
    targets = {
      sleep.enable = false;
      suspend.enable = false;
      hibernate.enable = false;
      "hybrid-sleep".enable = false;
    };
  };

  # Include useful installation tools
  environment.systemPackages = with pkgs; [
    # Standard installer tools
    parted
    gptfdisk
    cryptsetup

    # Your preferred tools
    git
    curl
    wget
    vim
    tmux

    # Network tools
    networkmanager
    wpa_supplicant
  ];

  # Enable SSH for remote installation
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = true;
    };
  };

  # Set a default password for installation (change after install!)
  users.users.root.password = "nixos";
  users.users.kilian.password = "nixos";

  # ISO boot configuration
  boot.loader.grub.device = lib.mkForce "/dev/disk/by-label/NIXOS_ISO";

  # Larger ISO if needed for all your services
  isoImage.squashfsCompression = "gzip";
}
