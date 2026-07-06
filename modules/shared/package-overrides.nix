_: {
  nixpkgs.overlays = [
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
