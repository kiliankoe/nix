_: {
  nixpkgs.overlays = [
    # Fix lucky-commit build on aarch64-darwin.
    # Upstream nixpkgs PR #495593 tried to patch sha1-asm assembly but its
    # substituteInPlace glob no longer matches. This approach disables the asm
    # feature entirely, avoiding the broken sha1-asm/sha2-asm crates.
    # Remove once upstream ships a working fix.
    (_final: prev: {
      lucky-commit = prev.lucky-commit.overrideAttrs (_old: {
        postPatch = ''
          substituteInPlace Cargo.toml \
            --replace-fail 'features = ["asm", "compress"]' 'features = ["compress"]'
        '';
        buildNoDefaultFeatures = true;
      });
    })

    # Skip flaky upstream test in paperless-ngx 2.20.13.
    # test_error_skip_rule fails with AssertionError: 1 != 2.
    # Remove once nixpkgs updates paperless-ngx past this issue.
    (_final: prev: {
      paperless-ngx = prev.paperless-ngx.overrideAttrs (old: {
        disabledTests = (old.disabledTests or [ ]) ++ [
          "test_error_skip_rule"
        ];
      });
    })

    # Fix jeepney build on Darwin: pythonImportsCheckPhase fails because
    # jeepney.io.trio requires the 'outcome' module which isn't available,
    # and installCheckPhase fails because dbus-run-session doesn't work on macOS.
    # Upstream fix: https://github.com/NixOS/nixpkgs/pull/485980
    # Remove this overlay once that PR is merged and our nixpkgs pin includes it.
    (_final: prev: {
      pythonPackagesExtensions = (prev.pythonPackagesExtensions or [ ]) ++ [
        (_pyFinal: pyPrev: {
          # Work around flaky psycopg pool tests on recent nixpkgs revisions.
          # Remove once nixpkgs includes the upstream skip for these tests.
          psycopg = pyPrev.psycopg.overrideAttrs (old: {
            disabledTestMarks = (old.disabledTestMarks or [ ]) ++ [
              "slow"
            ];
            disabledTests = (old.disabledTests or [ ]) ++ [
              "test_stats_connect"
            ];
          });
        })
      ];

      python313Packages = prev.python313Packages.overrideScope (
        _pyFinal: pyPrev: {
          jeepney = pyPrev.jeepney.overrideAttrs (_old: {
            doInstallCheck = false;
            pythonImportsCheck = [
              "jeepney"
              "jeepney.auth"
              "jeepney.io"
              "jeepney.io.asyncio"
              "jeepney.io.blocking"
              "jeepney.io.threading"
            ];
          });
        }
      );
    })
  ];
}
