{ pkgs, inputs, ... }:
{
  environment.systemPackages = with pkgs; [
    _1password-cli
    dedup-darwin
    terminal-notifier

    inputs.npr.packages.${pkgs.system}.default
  ];
}
