#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.11"
# ///
"""Lists apps in /Applications not managed by Homebrew casks or Mac App Store."""

import re
from pathlib import Path


def extract_casks(content: str) -> set[str]:
    """Extract cask names from nix file content."""
    pattern = r'^\s*"([a-z0-9-]+)"$'
    return set(re.findall(pattern, content, re.MULTILINE))


def extract_masapps(content: str) -> set[str]:
    """Extract masApp names from nix file content."""
    pattern = r'^\s*"([^"]+)"\s*='
    return set(re.findall(pattern, content, re.MULTILINE))


def normalize(name: str) -> str:
    """Normalize app name for comparison."""
    return (
        name.lower()
        .replace(" ", "")
        .replace(".", "")
        .replace("-", "")
        .removesuffix("app")
    )


def is_managed(app_name: str, casks: set[str], masapps: set[str]) -> bool:
    """Check if an app is managed by homebrew casks or masApps."""
    normalized = normalize(app_name)

    for cask in casks:
        cask_normalized = normalize(cask)
        if normalized in cask_normalized or cask_normalized in normalized:
            return True

    for masapp in masapps:
        masapp_normalized = normalize(masapp)
        if normalized in masapp_normalized or masapp_normalized in normalized:
            return True

    return False


APPLE_APPS = {
    "Asset Catalog Creator",
    "Books",
    "Calendar",
    "Clock",
    "Compressor",
    "Contacts",
    "FaceTime",
    "Find My",
    "Freeform",
    "GarageBand",
    "Home",
    "Mail",
    "Maps",
    "Messages",
    "Music",
    "News",
    "Notes",
    "Photo Booth",
    "Photos",
    "Podcasts",
    "Preview",
    "Reminders",
    "Safari",
    "Shortcuts",
    "Stocks",
    "TV",
    "Voice Memos",
    "Weather",
}

IGNORE = {"Utilities", "Nix Apps"}


def main():
    script_dir = Path(__file__).parent
    nix_dir = script_dir.parent

    # Collect all managed app identifiers from nix files
    homebrew_files = [
        nix_dir / "modules" / "darwin" / "homebrew.nix",
        *nix_dir.glob("hosts/*/homebrew.nix"),
    ]

    all_casks: set[str] = set()
    all_masapps: set[str] = set()

    for f in homebrew_files:
        if f.exists():
            content = f.read_text()
            all_casks.update(extract_casks(content))
            all_masapps.update(extract_masapps(content))

    # Find unmanaged apps
    applications = Path("/Applications")
    unmanaged = []

    for app in sorted(applications.iterdir()):
        if not (app.suffix == ".app" or app.suffix == ".localized"):
            continue

        app_name = app.stem

        if app_name in APPLE_APPS or app_name in IGNORE:
            continue

        if is_managed(app_name, all_casks, all_masapps):
            continue

        unmanaged.append(app_name)

    for app in unmanaged:
        print(app)

    print(f"\nTotal: {len(unmanaged)} unmanaged apps")


if __name__ == "__main__":
    main()
