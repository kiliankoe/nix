{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    delta
    devbox
    devenv
    emcee
    k9s
    kubectl
    npm-check
    pnpm
    python315
  ];
}
