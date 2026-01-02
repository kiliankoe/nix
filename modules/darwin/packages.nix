{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    openapi-tui

    # macOS-specific utilities
    dedup-darwin
    terminal-notifier
  ];
}
