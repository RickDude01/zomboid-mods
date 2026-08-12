#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
dist="$root/dist"
manual_root="$dist/manual-install/GunFirearmRattleSFX"
manual="$manual_root/42"
workshop="$dist/workshop/GunFirearmRattleSFX"

rm -rf "$dist"
mkdir -p "$manual" "$workshop/mods/GunFirearmRattleSFX"

# Build 42 loads version-specific content from the mod's 42 directory.
# Keep release output limited to installable runtime files and release docs.
cp "$root/mod.info" "$root/preview.png" "$root/README.md" "$root/CHANGELOG.md" "$manual/"
cp -R "$root/media" "$root/docs" "$root/licenses" "$manual/"

# Finder metadata is not part of a Project Zomboid package.
find "$manual" -name '.DS_Store' -delete

cp -R "$manual_root/." "$workshop/mods/GunFirearmRattleSFX/"
cp "$root/workshop/workshop.txt" "$workshop/workshop.txt"
cp "$root/workshop/description.txt" "$workshop/description.txt"

printf 'Built manual-install and Workshop distributions in %s\n' "$dist"
