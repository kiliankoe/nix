{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # Mariner-specific packages (server)
    docker-compose
    tmux
  ];
}