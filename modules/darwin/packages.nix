{ pkgs, inputs, ... }:
{
  environment.systemPackages = with pkgs; [
    openapi-tui

    # macOS-specific utilities
    _1password-cli
    dedup-darwin
    terminal-notifier

    inputs.npr.packages.${pkgs.system}.default
  ];
}
