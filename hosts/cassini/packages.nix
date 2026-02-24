{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    delta
    devbox
    devenv
    emcee
    glab
    k9s
    kubectl
    pnpm
  ];
}
