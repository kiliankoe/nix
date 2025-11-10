{
  # Common darwin host template with standard imports
  imports = [
    ../shared/common.nix
    ../shared/packages.nix
    ../shared/package-overrides.nix
    ../shared/sops.nix

    ./base.nix
    ./packages.nix
    ./homebrew.nix
  ];

  nixpkgs.hostPlatform = "aarch64-darwin";
}
