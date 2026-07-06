{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    acli
    delta
    devenv
    emcee
    glab
    k9s
    kubectl
    pnpm
  ];
}
