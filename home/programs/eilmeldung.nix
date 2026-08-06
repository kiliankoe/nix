{
  inputs,
  lib,
  osConfig,
  pkgs,
  ...
}:
let
  # eilmeldung execs `cmd:` secrets directly rather than through a shell, so an
  # `SOPS_AGE_KEY_FILE=… sops …` prefix would be read as the binary name.
  freshrssPassword = pkgs.writeShellScript "eilmeldung-freshrss-password" ''
    export SOPS_AGE_KEY_FILE=${osConfig.sops.age.keyFile}
    exec ${lib.getExe pkgs.sops} -d --extract '["freshrss"]["api_password"]' ${../../secrets/secrets.yaml}
  '';
in
{
  imports = [ inputs.eilmeldung.homeManager.default ];

  programs.eilmeldung = {
    enable = true;
    # Not in nixpkgs; take the package from its own flake rather than pulling in
    # the overlay just to satisfy the module's `pkgs.eilmeldung` default.
    package = inputs.eilmeldung.packages.${pkgs.stdenv.hostPlatform.system}.default;

    settings = {
      # FreshRSS is reached over its Google Reader API. The password is the
      # separate API password from the FreshRSS profile, not the login password.
      login_setup = {
        login_type = "direct_password";
        provider = "freshrss";
        url = "https://rss.kilko.de/api/greader.php/";
        user = "kilian";
        password = "cmd:${freshrssPassword}";
      };

      sync_every_minutes = 10;
      # Default is xdg-open, which doesn't exist here.
      enclosure_command = "open {url}";
    };
  };
}
