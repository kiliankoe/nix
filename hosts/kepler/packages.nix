{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    systemctl-tui
  ];
}
