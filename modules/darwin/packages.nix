{ pkgs, inputs, ... }:
{
  environment.systemPackages = with pkgs; [
    openapi-tui

    # macOS-specific utilities
    dedup-darwin
    terminal-notifier

    inputs.npr.packages.${pkgs.system}.default
  ];
}
