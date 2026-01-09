{
  config,
  pkgs,
  lib,
  ...
}:

let
  updateScript = pkgs.writeShellScript "flake-update" ''
        set -euo pipefail

        REPO_PATH="/home/kilian/nix"
        BRANCH="flake-updates"

        cd "$REPO_PATH"

        # Ensure we're on main and up to date
        ${pkgs.git}/bin/git checkout main
        ${pkgs.git}/bin/git pull origin main

        # Check if update branch exists, delete if so
        ${pkgs.git}/bin/git branch -D "$BRANCH" 2>/dev/null || true
        ${pkgs.git}/bin/git checkout -b "$BRANCH"

        # Update flake
        ${pkgs.nix}/bin/nix flake update

        # Check if there are changes
        if ${pkgs.git}/bin/git diff --quiet flake.lock; then
          echo "No updates available"
          ${pkgs.git}/bin/git checkout main
          exit 0
        fi

        # Build kepler to verify it works
        echo "Building kepler configuration..."
        ${pkgs.nix}/bin/nix build .#nixosConfigurations.kepler.config.system.build.toplevel

        # Generate diff summary using nvd
        OLD_SYSTEM=$(readlink -f /run/current-system)
        NEW_SYSTEM=$(readlink -f ./result)
        DIFF_OUTPUT=$(${pkgs.nvd}/bin/nvd diff "$OLD_SYSTEM" "$NEW_SYSTEM" 2>&1 || true)

        # Commit and push
        ${pkgs.git}/bin/git add flake.lock
        ${pkgs.git}/bin/git commit -m "chore: update flake inputs $(date +%Y-%m-%d)"
        ${pkgs.git}/bin/git push -u origin "$BRANCH" --force

        # Create or update PR using gh CLI
        EXISTING_PR=$(${pkgs.gh}/bin/gh pr list --head "$BRANCH" --json number --jq '.[0].number' 2>/dev/null || true)

        PR_BODY="## Flake Input Updates

    This PR was automatically created by kepler.

    ### Package Changes
    \`\`\`
    $DIFF_OUTPUT
    \`\`\`

    ### Verification
    - [x] kepler configuration builds successfully
    "

        if [ -n "$EXISTING_PR" ]; then
          echo "Updating existing PR #$EXISTING_PR"
          ${pkgs.gh}/bin/gh pr edit "$EXISTING_PR" --body "$PR_BODY"
        else
          echo "Creating new PR"
          ${pkgs.gh}/bin/gh pr create \
            --title "chore: update flake inputs $(date +%Y-%m-%d)" \
            --body "$PR_BODY" \
            --base main \
            --head "$BRANCH"
        fi

        # Cleanup
        ${pkgs.git}/bin/git checkout main
        rm -f result
  '';
in
{
  environment.systemPackages = [
    pkgs.gh
    pkgs.nvd
  ];

  systemd.services.flake-updater = {
    description = "Automatic flake.lock updater";
    serviceConfig = {
      Type = "oneshot";
      User = "kilian";
      ExecStart = updateScript;
      WorkingDirectory = "/home/kilian/nix";
    };
    path = [
      pkgs.git
      pkgs.nix
      pkgs.gh
      pkgs.nvd
    ];
  };

  systemd.timers.flake-updater = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "Sun 05:00";
      RandomizedDelaySec = "1h";
      Persistent = true;
    };
  };
}
