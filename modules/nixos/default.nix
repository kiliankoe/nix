{
  # Common nixos host template with standard imports
  imports = [
    ../shared/common.nix
    ../shared/packages.nix
    ../shared/sops.nix
    ./base.nix
  ];
}
