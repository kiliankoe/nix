{ pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    # nix stuff
    nh

    nil
    nixd
    nixfmt

    # languages, package managers, etc.
    bun
    go
    ni
    nodejs_24
    rustup
    uv

    # tools
    _1password-cli
    atuin
    bat
    biome
    btop
    claude-code
    codex
    ddate
    docker
    docker-compose
    eza
    fd
    gemini-cli
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
