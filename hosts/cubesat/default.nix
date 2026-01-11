{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/shared/common.nix
    ../../modules/shared/sops.nix
    ../../modules/nixos/base.nix
    # ../../services/pangolin.nix
    ./packages.nix
  ];

  networking.hostName = "cubesat";

  home-manager.users.kilian = {
    programs.tmux.extraConfig = ''
      set -g status-bg yellow
      set -g status-fg black
      set -g pane-active-border-style bg=default,fg=yellow
    '';
  };
}
