{ pkgs, ... }:
{
  nixpkgs.overlays = [
    (final: prev: {
      # Fix lucky-commit build on aarch64-darwin
      # The sha1-asm/sha2-asm dependencies fail with Clang 21+ due to assembly syntax issues
      # Override to disable asm features which depend on these broken packages
      lucky-commit = prev.lucky-commit.overrideAttrs (old: {
        # Patch Cargo.toml to remove asm features from sha-1 and sha2 dependencies
        postPatch = ''
          substituteInPlace Cargo.toml \
            --replace-fail 'features = ["asm", "compress"]' 'features = ["compress"]'
        '';
        # Also disable OpenCL which isn't needed
        buildNoDefaultFeatures = true;
      });
    })
  ];
}
