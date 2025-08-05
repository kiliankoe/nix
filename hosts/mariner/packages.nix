{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    docker-compose
    tmux
  ];
}
