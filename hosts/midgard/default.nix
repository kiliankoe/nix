{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/base.nix
    ../../modules/shared/base.nix
    # ../../modules/shared/tmux.nix
    ../../modules/shared/zsh.nix
    ./packages.nix
  ];

  # Networking
  networking.hostName = "midgard";

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

  # User packages (desktop-specific)
  users.users.kilian.packages = with pkgs; [
    kdePackages.kate
  ];

  # Services (desktop-specific)
  programs.firefox.enable = true;
  services.printing.enable = true;
}
