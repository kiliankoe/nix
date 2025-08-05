{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # macOS-specific utilities
    mas
    terminal-notifier
  ];
}
