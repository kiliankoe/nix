{ pkgs, ... }:
{

  environment.systemPackages = with pkgs; [
    # nix
    nh
    nixfmt
    statix
    deadnix

    # tools
    age
    atuin
    bat
    btop
    claude-code
    docker
    docker-compose
    dua
    eza
    fd
    git
    helix
    jq
    lazygit
    ripgrep
    rustypaste-cli
    sops
    tmux
    tree
    uv
    vim
    witr
  ];
}
