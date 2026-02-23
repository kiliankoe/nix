{ pkgs, inputs, ... }:
{
  environment.systemPackages = with pkgs; [
    openapi-tui
    yt-dlp

    # macOS-specific utilities
    _1password-cli
    dedup-darwin
    terminal-notifier

    inputs.npr.packages.${pkgs.system}.default
  ];
}
