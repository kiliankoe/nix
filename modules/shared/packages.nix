{ pkgs, ... }:
{

  environment.systemPackages = with pkgs; [
    # nix stuff
    nh
    nil
    nixd
    nixfmt
    statix
    deadnix

    # languages, package managers, etc.
    bun
    ni
    nodejs_24
    rustup
    uv

    # tools
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
    github-copilot-cli
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
    opencode
    ripgrep
    ripgrep-all
    rustypaste-cli
    sops
    tealdeer
    tmux
    tokei
    tree
    vim
    witr
    yazi
    zola
  ];
}
