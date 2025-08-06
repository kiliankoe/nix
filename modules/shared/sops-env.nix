{ config, pkgs, ... }:
{
  sops.age.keyFile = "$HOME/.config/age/key.txt";
  sops.defaultSopsFile = ../../secrets.yaml;

  # Common secret definitions
  sops.secrets = {
    "env/openai_api_key" = { };
  };

  # Create a script that exports environment variables from sops secrets
  environment.etc."sops-env.sh" = {
    text = ''
      export OPENAI_API_KEY="$(cat ${
        config.sops.secrets."env/openai_api_key".path
      } 2>/dev/null || echo "")"
    '';
    mode = "0644";
  };
}
