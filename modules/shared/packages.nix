{ pkgs, ... }:
{

  environment.systemPackages = with pkgs; [
    # nix stuff
    nh
    nil
    nixd
    nixfmt
    statix

    # languages, package managers, etc.
    bun
    ni
    nodejs_24
    rustup
    uv

    # tools
    _1password-cli
    age
    atuin
    bat
    biome
    btop
    claude-code
    codex
    ddate
    dive
    docker
    docker-compose
    dua
    eza
    fd
    ffmpeg
    genact
    git
    gping
    heh
    helix
    hyperfine
    jq
    lazygit
    lucky-commit
    lychee
    mitmproxy
    mitmproxy2swagger
    neofetch
    ripgrep
    ripgrep-all
    sops
    tealdeer
    tmux
    tokei
    tree
    vim
    witr
    yazi
    yt-dlp
    zola
  ];
}
