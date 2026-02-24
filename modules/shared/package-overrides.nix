_: {
  nixpkgs.overlays = [
    (_final: prev: {
      # Fix lucky-commit build on aarch64-darwin
      # The sha1-asm/sha2-asm dependencies fail with Clang 21+ due to assembly syntax issues
      # Override to disable asm features which depend on these broken packages
      lucky-commit = prev.lucky-commit.overrideAttrs (_old: {
        # Patch Cargo.toml to remove asm features from sha-1 and sha2 dependencies
        postPatch = ''
          substituteInPlace Cargo.toml \
            --replace-fail 'features = ["asm", "compress"]' 'features = ["compress"]'
        '';
        # Also disable OpenCL which isn't needed
        buildNoDefaultFeatures = true;
      });
    })

    # Fix jeepney build on Darwin: pythonImportsCheckPhase fails because
    # jeepney.io.trio requires the 'outcome' module which isn't available,
    # and installCheckPhase fails because dbus-run-session doesn't work on macOS.
    # Upstream fix: https://github.com/NixOS/nixpkgs/pull/485980
    # Remove this overlay once that PR is merged and our nixpkgs pin includes it.
    (_final: prev: {
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
