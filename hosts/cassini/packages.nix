{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    delta
    devbox
    devenv
    direnv
    emcee
    k9s
    kubectl
    npm-check
    pnpm
  ];
}
