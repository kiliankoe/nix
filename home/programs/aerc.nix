{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:
let
  # aerc runs cred commands through `sh -c`, so a plain sops invocation would work
  # inline. Keeping it in a script matches eilmeldung.nix and keeps the exports and
  # the extract path in one place.
  sopsExtract =
    name: path:
    pkgs.writeShellScript name ''
      export SOPS_AGE_KEY_FILE=${osConfig.sops.age.keyFile}
      exec ${lib.getExe pkgs.sops} -d --extract '${path}' ${../../secrets/secrets.yaml}
    '';

  # Same path home-manager's aerc module writes to, and the one aerc itself reads on
  # darwin when XDG_CONFIG_HOME is unset.
  aercDir =
    if config.xdg.enable then
      "${config.xdg.configHome}/aerc"
    else
      "${config.home.homeDirectory}/Library/Preferences/aerc";
in
{
  programs.aerc = {
    enable = true;

    # withNotmuch is the package default and drags in notmuch -> emacs -> mailutils,
    # which fails to link on aarch64-darwin. JMAP searches server-side, so the notmuch
    # backend would go unused here regardless.
    package = pkgs.aerc.override { withNotmuch = false; };

    # home-manager writes accounts.conf into the nix store (0444) and aerc refuses to
    # read a world-readable accounts file without this. Nothing secret is in it: both
    # credentials come from cred commands.
    extraConfig.general.unsafe-accounts-conf = true;

    # Writing any aerc.conf shadows the one shipped in the package, and filters are the
    # only settings that live there rather than as compiled-in defaults. Without this
    # every part renders as "No filter configured for this mimetype". Restated verbatim
    # from share/aerc/aerc.conf; the scripts come from the package's libexec, which aerc
    # prepends to PATH. Order matters (first match wins), and home-manager sorts keys
    # alphabetically, so a wildcard like `text/*` would sort ahead of and swallow the
    # entries below it.
    extraConfig.filters = {
      ".headers" = "colorize";
      "message/delivery-status" = "colorize";
      "message/rfc822" = "colorize";
      "text/calendar" = "calendar";
      # `!` lets the filter handle its own paging.
      "text/html" = "! html";
      "text/plain" = "colorize";
    };

    extraAccounts.fastmail = {
      from = "Kilian Koeltzsch <me@kilian.io>";

      # Fastmail recommends JMAP over IMAP, and outgoing mail reuses the same
      # connection, so a single API token (mail scope) covers both directions.
      source = "jmap+oauthbearer://api.fastmail.com/jmap/session";
      source-cred-cmd = "${sopsExtract "aerc-fastmail-token" ''["fastmail"]["api_token"]''}";
      outgoing = "jmap://";

      default = "Inbox";
      folders-sort = "Inbox";

      # JMAP mailboxes are labels rather than folders; this exposes the virtual
      # all-mail folder and :modify-labels. Message bodies stay uncached because that
      # cache grows without bound and has to be pruned by hand.
      use-labels = true;
      cache-state = true;
      cache-blobs = false;

      # Contacts use a separate Fastmail app password limited to CardDAV.
      carddav-source = "https://me%40kilian.io@carddav.fastmail.com/dav/addressbooks/user/me@kilian.io/Default";
      carddav-source-cred-cmd = "${sopsExtract "aerc-fastmail-carddav" ''["fastmail"]["carddav_password"]''}";
      # carddav-query reads the URL and cred command out of accounts.conf itself, but
      # defaults to ~/.config/aerc/accounts.conf, which is not where home-manager puts
      # it on darwin.
      address-book-cmd = "carddav-query -c ${aercDir}/accounts.conf -S fastmail %s";
    };
  };
}
