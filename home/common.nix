{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./programs/direnv.nix
    ./programs/git.nix
    ./programs/helix.nix
    ./programs/sops-env.nix
    ./programs/tmux.nix
    ./programs/zoxide.nix
    ./programs/zsh.nix
  ];

  home.username = "kilian";
  home.stateVersion = "24.05";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    # Development tools that are user-specific
    # (system-wide tools remain in system configuration)
  ];

  # Common environment variables
  home.sessionVariables = {
    EDITOR = "hx";
  };
}
