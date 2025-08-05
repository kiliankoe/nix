{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    _1password-cli
    biome
    claude-code
    codex
    delta
    devbox
    devenv
    direnv
    emcee
    eza
    gemini-cli
    git-vanity-hash
    k9s
    kubectl
    llm
    ni
    nil
    nixd
    nixpkgs-fmt
    npm-check
    pnpm
    ripgrep-all
    rustup
    smug
    switchaudio-osx
    tailscale
    yq
  ];

  nixpkgs.config.allowUnfree = true;
}
