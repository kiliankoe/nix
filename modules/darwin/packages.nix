{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # macOS-specific utilities
    dedup-darwin
    terminal-notifier
  ];
}
