{ pkgs, ... }:
{

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
    age
    atuin
    bat
    biome
    btop
    claude-code
    # codex # currently installed via homebrew to keep it more up-to-date
    ddate
    docker
    docker-compose
    eza
    fd
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
    ripgrep-all
    sops
    tealdeer
    tmux
    tokei
    tree
    vim
    yt-dlp
  ];
}
