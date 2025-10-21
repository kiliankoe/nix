{
  config,
  pkgs,
  lib,
  osConfig,
  ...
}:
{
  # Create base sops environment script with common exports
  # Platform-specific secrets are added in home/darwin.nix or home/nixos.nix
  home.activation.sopsEnvBase = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        echo "Creating sops environment script..."
        mkdir -p "$HOME/.config/sops"
        cat > "$HOME/.config/sops/env.sh" << 'EOF'
    # Common sops exports
    export SOPS_AGE_KEY_FILE="${osConfig.sops.age.keyFile}"
    EOF
        chmod 600 "$HOME/.config/sops/env.sh"
  '';
}
