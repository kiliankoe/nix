{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # Sojourner-specific packages (work-related)
    _1password-cli
    biome
    claude-code
    codex
    delta
    devbox
    devenv
    direnv
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
    tailscale
    yq
  ];
  
  nixpkgs.config.allowUnfree = true;
}