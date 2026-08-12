{
  pkgs,
  inputs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    _1password-cli
    dedup-darwin
    mosh
    deploy-rs

    inputs.hister.packages.${pkgs.stdenv.hostPlatform.system}.default
    inputs.miniqdb.packages.${pkgs.stdenv.hostPlatform.system}.mqdb
  ];
}
