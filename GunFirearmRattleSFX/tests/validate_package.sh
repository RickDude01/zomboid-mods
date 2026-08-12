#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
"$root/tools/build-distributions.sh"

dist="$root/dist"
manual="$dist/manual-install/GunFirearmRattleSFX"
workshop="$dist/workshop/GunFirearmRattleSFX"

for package in "$manual" "$workshop/mods/GunFirearmRattleSFX"; do
    [[ -f "$package/mod.info" && -f "$package/media/sound/GunFirearmRattleSFX.snd" ]] || {
        echo "missing runtime structure in $package" >&2; exit 1;
    }
    [[ -d "$package/media/lua/client" && -d "$package/media/lua/shared" ]] || {
        echo "missing Lua structure in $package" >&2; exit 1;
    }
    [[ -f "$package/preview.png" ]] || { echo "missing preview in $package" >&2; exit 1; }
    [[ -f "$package/licenses/LICENSE-MIT.txt" && -f "$package/licenses/LICENSE-CC-BY-4.0.txt" ]] || {
        echo "missing licenses in $package" >&2; exit 1;
    }
    [[ -f "$package/docs/PROVENANCE.md" && -f "$package/docs/COMPATIBILITY.md" ]] || {
        echo "missing release docs in $package" >&2; exit 1;
    }
    if find "$package" -type f \( -name '*.DS_Store' -o -path '*/tests/*' -o -path '*/tools/*' \) | grep -q .; then
        echo "development-only files leaked into $package" >&2; exit 1
    fi
done

grep -q '^id=GunFirearmRattleSFX$' "$manual/mod.info"
grep -q '^author=timtim$' "$manual/mod.info"
grep -q '^version=0.1.0$' "$manual/mod.info"
grep -q '^visibility=unlisted$' "$workshop/workshop.txt"
grep -q '^tags=Build 42,Audio,Realistic,Weapons,QoL$' "$workshop/workshop.txt"
grep -q 'macOS.*42.20.2' "$manual/README.md"
grep -qi 'Windows and Linux' "$manual/README.md"
grep -qi 'unverified' "$manual/README.md"
grep -qi 'multiplayer.*untested' "$manual/README.md"

command -v sips >/dev/null || { echo "sips is required to inspect preview dimensions" >&2; exit 1; }
preview_size="$(sips -g pixelWidth -g pixelHeight "$manual/preview.png" | awk '/pixelWidth|pixelHeight/ { print $2 }' | tr '\n' ' ')"
[[ "$preview_size" == "256 256 " ]] || { echo "preview must be 256x256: $preview_size" >&2; exit 1; }

if rg -n 'sendClientCommand|sendServerCommand|WorldSound|addWorldSound|Events\.OnServer' "$manual/media/lua"; then
    echo "forbidden network/server/world-noise operation found" >&2; exit 1
fi

echo "package validation: manual and Workshop layouts, metadata, assets, docs, licenses, preview, and client-only checks passed"
