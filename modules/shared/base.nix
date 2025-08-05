{ pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    # nix stuff
    nh
    nixfmt

    # languages, package managers, etc.
    bun
    go
    nodejs_24
    rustup
    uv

    # tools
    atuin
    bat
    btop
    claude-code
    codex
    ddate
    docker
    docker-compose
    fd
    git
    gping
    heh
    helix
    hyperfine
    jq
    lazygit
    lucky-commit
    mitmproxy
    mitmproxy2swagger
    neofetch
    ripgrep-all
    tealdeer
    tmux
    tokei
    tree
    vim
    yt-dlp
  ];
}
