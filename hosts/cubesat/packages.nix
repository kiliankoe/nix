{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    btop
    helix
    lazygit
    nh
    ripgrep
  ];
}
