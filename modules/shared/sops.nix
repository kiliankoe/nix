{ config, pkgs, ... }:
{
  sops.age.keyFile = "$HOME/.config/sops/age.key";
  sops.defaultSopsFile = ../../secrets.yaml;

  # Common secret definitions
  sops.secrets = {
    "env/openai_api_key" = { };
  };

  # Create a script to export secrets, sourced in zsh.nix
  system.activationScripts.sopsEnv.text = ''
        echo "Creating sops environment script..."
        mkdir -p "$HOME/.config/sops"
        cat > "$HOME/.config/sops/env.sh" << 'EOF'
    export OPENAI_API_KEY="$(cat ${
      config.sops.secrets."env/openai_api_key".path
    } 2>/dev/null || echo "")"
    EOF
        chmod 644 "$HOME/.config/sops/env.sh"
  '';
}
