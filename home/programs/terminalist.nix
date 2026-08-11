{
  inputs,
  lib,
  osConfig,
  pkgs,
  ...
}:
let
  src = inputs.terminalist;
  upstreamVersion = (lib.importTOML "${src}/Cargo.toml").package.version;
  # Tracking main, so name it the nixpkgs way: "20260325091840" -> "2026-03-25".
  commitDate = lib.concatStringsSep "-" (builtins.match "(....)(..)(..).*" src.lastModifiedDate);
  # Not in nixpkgs and homebrew is also built from source (no bottle) and stale.
  terminalist = pkgs.rustPlatform.buildRustPackage {
    pname = "terminalist";
    version = "${upstreamVersion}-unstable-${commitDate}";
    inherit src;
    cargoLock.lockFile = "${inputs.terminalist}/Cargo.lock";
    preCheck = "export HOME=$(mktemp -d)";

    meta = {
      description = "Terminal-based Todoist client";
      homepage = "https://github.com/romaintb/terminalist";
      license = lib.licenses.mit;
      mainProgram = "terminalist";
    };
  };
in
{
  # The API token is read from the env and nowhere else, the config has no field for it.
  # Decrypting per launch keeps it out of the store and every process's env.
  home.packages = [
    (pkgs.writeShellScriptBin "terminalist" ''
      export TODOIST_API_TOKEN="$(
        SOPS_AGE_KEY_FILE=${osConfig.sops.age.keyFile} \
          ${lib.getExe pkgs.sops} -d --extract '["todoist"]["api_token"]' ${../../secrets/secrets.yaml}
      )"
      exec ${lib.getExe terminalist} "$@"
    '')
  ];
}
