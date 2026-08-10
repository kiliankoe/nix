{
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ./programs/claude.nix
    ./programs/direnv.nix
    ./programs/git.nix
    ./programs/helix.nix
    ./programs/lazygit.nix
    ./programs/sops-env.nix
    ./programs/starship.nix
    ./programs/tig.nix
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
    EDITOR = lib.mkDefault "hx";
    # Pin <nixpkgs> to the rev this system was built from. Without it, comma
    # resolves <nixpkgs> to the channel fallback and downloads/evaluates
    # nixpkgs-unstable from scratch. Set here rather than via nix.nixPath
    # because Determinate manages nix on darwin (nix.enable = false), which
    # leaves nix-darwin's nix.* options inert.
    NIX_PATH = "nixpkgs=${inputs.nixpkgs}";
  };
}
