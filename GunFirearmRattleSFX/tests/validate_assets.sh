#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
audio_dir="$root/media/sound/GunFirearmRattleSFX"
sound_manifest="$root/media/sound/GunFirearmRattleSFX.snd"
engine="$root/media/lua/shared/GunFirearmRattleSFX/DecisionEngine.lua"
provenance="$root/docs/PROVENANCE.md"

command -v ffprobe >/dev/null || { echo "ffprobe is required" >&2; exit 1; }
command -v ffmpeg >/dev/null || { echo "ffmpeg is required" >&2; exit 1; }
command -v luajit >/dev/null || { echo "luajit is required" >&2; exit 1; }

clips=()
while IFS= read -r clip; do clips+=("$clip"); done < <(find "$audio_dir" -type f -name '*.ogg' -print | sort)
[[ "${#clips[@]}" -eq 8 ]] || { echo "expected 8 OGG clips, found ${#clips[@]}" >&2; exit 1; }

hashes_file="$(mktemp)"
trap 'rm -f "$hashes_file"' EXIT
for clip in "${clips[@]}"; do
    name="$(basename "$clip" .ogg)"
    [[ "$name" =~ ^(handgun|longgun)_[0-9]{2}$ ]] || { echo "invalid clip name: $name" >&2; exit 1; }
    profile="${BASH_REMATCH[1]}"
    shasum -a 256 "$clip" | awk '{print $1}' >> "$hashes_file"

    IFS=, read -r codec rate channels duration < <(ffprobe -v error -select_streams a:0 \
        -show_entries stream=codec_name,sample_rate,channels,duration \
        -of csv=p=0:s=, "$clip")
    [[ "$codec" == "vorbis" && "$rate" == "44100" && "$channels" == "1" ]] || {
        echo "invalid format: $clip ($codec $rate Hz $channels channels)" >&2; exit 1;
    }
    awk -v duration="$duration" 'BEGIN { exit !(duration >= 0.15 && duration <= 0.35) }' || {
        echo "duration outside 150-350 ms: $clip ($duration s)" >&2; exit 1;
    }
    peak="$(ffmpeg -v info -i "$clip" -af volumedetect -f null - 2>&1 | awk '/max_volume/ { print $5; exit }')"
    [[ -n "$peak" ]] || { echo "could not inspect peak: $clip" >&2; exit 1; }
    awk -v peak="$peak" 'BEGIN { gsub("dB", "", peak); exit !(peak <= 0) }' || {
        echo "clipping detected: $clip ($peak)" >&2; exit 1;
    }
done
[[ "$(sort -u "$hashes_file" | wc -l | tr -d ' ')" -eq 8 ]] || { echo "clips must be byte-distinct" >&2; exit 1; }

for sample in Handgun01 Handgun02 Handgun03 Handgun04 LongGun01 LongGun02 LongGun03 LongGun04; do
    grep -q "GunFirearmRattleSFX_${sample}" "$sound_manifest" || { echo "missing sound reference: $sample" >&2; exit 1; }
done
grep -q 'Handgun01.*Handgun02.*Handgun03.*Handgun04' "$engine" || { echo "handgun pool mismatch" >&2; exit 1; }
grep -q 'LongGun01.*LongGun02.*LongGun03.*LongGun04' "$engine" || { echo "long-gun pool mismatch" >&2; exit 1; }
grep -qi 'original.*procedural\|CC BY 4.0' "$provenance" || { echo "provenance ledger is incomplete" >&2; exit 1; }

(cd "$root" && luajit tests/decision_engine_test.lua)
echo "asset validation: 8 unique clips, format/duration/peak/references/provenance checks passed"
