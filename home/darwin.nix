{
  lib,
  osConfig,
  ...
}:
{
  imports = [
    ./programs/zed.nix
  ];

  home.sessionVariables = {
    # macOS uses 'open' for default browser
    BROWSER = "open";
  };

  home.homeDirectory = lib.mkForce "/Users/kilian";

  # Add darwin-specific secret exports to sops env.sh
  home.activation.sopsEnvDarwin = lib.hm.dag.entryAfter [ "sopsEnvBase" ] ''
        cat >> "$HOME/.config/sops/env.sh" << 'EOF'

    # Darwin-specific secrets
    export HOMEBREW_GITHUB_API_TOKEN="$(cat ${
      osConfig.sops.secrets."env/homebrew_github_api_token".path
    } 2>/dev/null || echo "")"
    EOF
  '';

  programs.zsh = {
    initContent = ''
      alias brewout="brew outdated"
      alias brewup="brew upgrade && brew cleanup"
      alias nu="cd ~/nix && nix flake update && cd -"
      alias nhb="nh darwin build -H $(hostname -s) ~/nix"
      alias nhs="nh darwin switch -H $(hostname -s) ~/nix"
      # BSD ls flags
      alias ls='ls -G'
      alias l='ls -lAhG'

      # Homebrew
      eval "$(/opt/homebrew/bin/brew shellenv)"
    '';
  };
}
