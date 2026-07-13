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

    inputs.hister.packages.${pkgs.system}.default

    # inputs.npr.packages.${pkgs.system}.default
  ];
}
