{ inputs, lib, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/shared/common.nix
    ../../modules/shared/packages.nix
    ../../modules/shared/packages-workstation.nix
    ../../modules/shared/package-overrides.nix
    ../../modules/shared/sops.nix
    ../../modules/nixos/base.nix
    ../../modules/nixos/docker.nix
  ];

  networking.hostName = "phobos";

  # KDE Plasma 6
  services.desktopManager.plasma6.enable = true;
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;

  # UTM/SPICE guest integration (auto-resize, clipboard sharing)
  services.spice-vdagentd.enable = true;
  services.qemuGuest.enable = true;

  # Audio
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  # Desktop user groups
  users.users.kilian.extraGroups = [
    "audio"
    "video"
  ];

  home-manager.users.kilian = {
    home.packages = [
      inputs.zen-browser.packages.aarch64-linux.default
    ];
    home.sessionVariables.BROWSER = lib.mkForce "zen";
    programs.tmux.extraConfig = ''
      set -g status-bg cyan
      set -g status-fg black
      set -g pane-active-border-style bg=default,fg=cyan
    '';
    programs.starship.settings.hostname.format = "[$hostname ](bold cyan)";
  };
}
