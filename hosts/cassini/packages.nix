{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    acli
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
