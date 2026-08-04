{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    acli
    azure-cli
    delta
    devenv
    emcee
    glab
    k9s
    kubectl
    kubelogin
    kubernetes-helm
    kustomize
    natscli
    pnpm
  ];
}
