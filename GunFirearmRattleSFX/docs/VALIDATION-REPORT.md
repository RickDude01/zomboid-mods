# v0.1.0 Validation Report

Date: 2026-08-11
Candidate: Gun / Firearm Rattle SFX 0.1.0
Target: Project Zomboid Build 42.20.2 on macOS

## Automated and package validation

Passed on the candidate source tree:

- `tests/validate_assets.sh`
  - Decision-engine behavior: 23 passed
  - Compatibility API: 4 passed
  - Mod options: passed
  - Eight unique mono 44.1 kHz OGG clips, duration and peak checks: passed
  - Sound references and provenance checks: passed
- `tests/validate_package.sh`
  - Manual-install and Workshop layouts: passed
  - Metadata, preview dimensions, docs, licenses, and client-only checks: passed

The generated distributions are disposable build output under `dist/` and are
not source-of-truth files.

## Local game environment

The installed game reports `42.20.2 ffe7a8a4b1`, matching the candidate's
documented baseline. The live `~/Zomboid/mods` directory did not contain
`GunFirearmRattleSFX` during this validation, so no clean install/load was
claimed from the existing game logs.

The available logs contain warnings and errors from other installed mods. They
cannot establish a clean log result for this candidate, and no
`GunFirearmRattleSFX` runtime entries were found.

## Release-owner checks still open

The following require an interactive game session and listening approval:

- `Base.Pistol`, `Base.Shotgun`, and optional `Base.Pistolm93r` held/attached
  matrix.
- Mixed priority, one-profile/no-layering, cadence, suppression, live settings,
  and hearing-trait checks.
- Sustained listening for cadence, realism, repetition, and mix against vanilla
  footsteps, combat, weapon handling, ambience, and threats.
- Explicit release-owner approval.

Multiplayer remains expected but unverified, and Steam Workshop publication
remains a separate explicit action.

Until those checks are completed, this candidate is code-complete but not
release-ready.
