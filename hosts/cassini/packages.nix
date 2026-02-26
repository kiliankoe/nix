{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    delta
    devbox
    devenv
    emcee
    glab
    jira-cli-go
    k9s
    kubectl
    pnpm
  ];
}
