{ ... }:
{
  imports = [
    ./hardware-configuration.nix

    ../../modules/shared/common.nix
    ../../modules/shared/packages.nix
    ../../modules/shared/sops.nix

    ../../modules/nixos/base.nix

    ./home.nix
    ./system.nix
    ./systemd.nix
    ./services
  ];
}
