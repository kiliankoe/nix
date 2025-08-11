{ config, pkgs, lib, ... }:
{
  # TODO: Read this from op? At least on macOS?
  sops.age.keyFile = if pkgs.stdenv.isDarwin
    then "/Users/kilian/.config/sops/age.key"
    else "/home/kilian/.config/sops/age.key";
  sops.defaultSopsFile = ../../secrets/secrets.yaml;

  # Common secret definitions
  sops.secrets = {
    "env/homebrew_github_api_token" = { };
  };

  # Create a script to export secrets, sourced in zsh.nix
  system.activationScripts.sopsEnv.text = ''
        echo "Creating sops environment script..."
        mkdir -p "$HOME/.config/sops"
        cat > "$HOME/.config/sops/env.sh" << 'EOF'
    export HOMEBREW_GITHUB_API_TOKEN="$(cat ${
      config.sops.secrets."env/homebrew_github_api_token".path
    } 2>/dev/null || echo "")"
    EOF
        chmod 644 "$HOME/.config/sops/env.sh"
  '';
}
