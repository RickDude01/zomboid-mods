# Gun / Firearm Rattle SFX v0.1.0

## Problem Statement

Project Zomboid communicates footsteps and firearm handling, but ordinary non-aiming movement does not consistently convey the physical presence of a carried firearm. A holstered handgun or slung long gun should subtly shift, creak, and tap as the survivor moves. Without that detail, equipped weapons can feel visually present but acoustically weightless.

The missing sound must be solved without changing stealth balance, attracting zombies, requiring server installation, or filling the soundscape with repetitive noise. It must also recognize compatible modded firearms, remain configurable for players with different repetition tolerances, and respect character hearing traits.

## Solution

Create a Build 42 client-side mod named **Gun / Firearm Rattle SFX**. During ordinary grounded movement, the mod will inspect firearms held or visibly attached to the local character and intermittently play short, step-aligned Foley accents. Handguns use a light holster-and-hardware profile; long guns use a heavier sling-and-stock profile.

The effect will be self-only and cosmetic. It will never generate world noise, attract zombies, transmit network state, or require server installation. Playback will be perceptually synchronized from movement distance and locomotion state, varied across eight original audio samples, and governed by deterministic priority, suppression, hearing, and configuration rules.

Players will control enablement, volume, and frequency through Build 42's native Mod Options panel. Other firearm mods will work automatically where their item metadata is well formed, with a stable exact-item override API and diagnostics for edge cases.

## User Stories

1. As a Project Zomboid player, I want a carried firearm to make subtle movement noise, so that the weapon feels physically present.
2. As a player carrying a handgun, I want light holster, fabric, and hardware movement, so that its sound matches its size and carry method.
3. As a player carrying a rifle or shotgun, I want heavier sling, stock, buckle, and hardware movement, so that long guns feel distinct from handguns.
4. As a player walking normally, I want firearm Foley aligned with my steps, so that the effect feels connected to movement.
5. As a crouch-walking player, I want quieter and less frequent firearm Foley, so that careful movement sounds restrained.
6. As a jogging player, I want stronger and more frequent movement accents, so that the sound reflects increased gear motion.
7. As a sprinting player, I want the strongest and fastest eligible accents, so that the sound reflects vigorous movement.
8. As an injured player, I want the effect to follow my actual slower travel distance, so that limping does not use an implausibly fast cadence.
9. As a stationary player, I want no firearm movement sound, so that the mod does not invent motion while I am idle.
10. As an aiming player, I want this mod to remain silent, so that it does not duplicate Build 42's built-in aiming-movement audio.
11. As a player vaulting, climbing, falling, or getting up, I want this mod to remain silent, so that generic step accents are not attached to mismatched special animations.
12. As a player entering or occupying a vehicle, I want this mod to remain silent, so that vehicle actions do not trigger locomotion Foley.
13. As a player dragging a corpse or carrying a large animal or heavy object, I want this mod to remain silent, so that alternate locomotion animations are not mistimed.
14. As a player equipping, drawing, attaching, or holstering a firearm, I want the mod to avoid custom handling sounds, so that it stays focused on locomotion Foley.
15. As a player with a firearm in my inventory but not equipped or attached, I want it to remain silent, so that stored items are not treated as body-mounted gear.
16. As a player with a firearm in either hand, I want it recognized as held, so that active carry can influence the sound.
17. As a player with a firearm in a holster, sling, back, or other visible attachment slot, I want it recognized as attached, so that loose body-mounted gear can rattle.
18. As a player holding a firearm, I want it quieter than an attached firearm, so that active stabilization is reflected acoustically.
19. As a player carrying several firearms, I want only one profile at a time, so that the effect does not become cluttered.
20. As a player carrying several firearms, I want attached long guns prioritized over held long guns, attached handguns, and held handguns, so that the loosest and heaviest qualifying gear dominates.
21. As a player carrying two qualifying firearms of the same priority, I want one deterministic profile rather than layered playback, so that the mix remains controlled.
22. As a player carrying a broken, unloaded, suppressed, or modified firearm, I want ordinary carry Foley to remain based on class and carry state, so that condition and attachments do not create unsupported sound combinations.
23. As a player using a bow, crossbow, slingshot, or other non-firearm ranged weapon, I want no firearm rattle, so that the sound remains physically coherent.
24. As a player using vanilla Build 42 firearms, I want automatic classification, so that no manual configuration is necessary.
25. As a player using a well-authored firearm mod, I want its firearms recognized automatically, so that the Foley mod works across my loadout.
26. As a player using an older firearm mod, I want conservative legacy detection, so that gun-specific metadata can still identify firearms without accepting every ranged weapon.
27. As a player using an ambiguous tagged firearm, I want a sensible class fallback, so that the item makes a plausible sound instead of being ignored.
28. As a player using a malformed item from another mod, I want gameplay to continue without popups or repeated errors, so that compatibility problems do not break my session.
29. As a player, I want enough sample variation to avoid hearing an obvious loop, so that the effect remains immersive during long walks.
30. As a player, I want immediate sample repeats prevented, so that randomness does not create conspicuous duplication.
31. As a player, I want custom accents prevented from overlapping, so that rapid movement does not create a noisy stack.
32. As a player, I want a maximum random silent streak, so that the mod never appears to have stopped working.
33. As a player, I want dry, short Foley without environmental ambience baked in, so that the samples fit varied game locations.
34. As a player, I want indoor location, outdoor location, weather, and floor material to leave the firearm profile unchanged in v0.1.0, so that the initial sound set remains focused and consistent.
35. As a player, I want the effect mixed below footsteps, combat, weapon handling, and environmental threats, so that it enriches rather than dominates the soundscape.
36. As a player, I want subtle pitch and gain variation, so that repeated accents sound organic without implying differently sized weapons.
37. As a player, I want to enable or disable the effect globally, so that I can opt out without uninstalling the mod.
38. As a player, I want a 0–100% volume control, so that I can fit the Foley to my audio setup.
39. As a player, I want five named frequency levels, so that I can tune repetition without interpreting raw probability.
40. As a new user, I want the effect enabled at a restrained default, so that the intended experience works immediately.
41. As a player, I want settings applied immediately, so that I can tune the effect without restarting or reloading a save.
42. As a player, I want settings shared across saves and servers, so that my audio preferences follow me.
43. As a Deaf character, I want the custom Foley fully suppressed, so that diegetic sound respects the trait.
44. As a Hard of Hearing character, I want the effect reduced, so that the trait influences the custom sound without making it unusably faint.
45. As a Keen Hearing character, I want the close self-Foley left at normal volume, so that the trait does not upset the intended mix.
46. As a player changing weapons or attachment slots, I want classification updated by the next movement step, so that the sound matches my current loadout.
47. As a single-player user, I want the mod to run entirely on my client, so that it has no server or world simulation overhead.
48. As an online multiplayer user, I want the mod designed to remain client-side and self-only, so that a server need not install it.
49. As another nearby human player, I should not hear someone else's custom firearm Foley, so that no custom audio state must be synchronized.
50. As a server operator, I want the mod to send no network messages or world-noise events, so that it cannot alter server gameplay.
51. As a mod author, I want to register an exact item ID as handgun, long gun, or silent, so that I can correct an automatic classification.
52. As a mod author, I want explicit classification to override heuristics, so that compatibility patches are deterministic.
53. As a compatibility-patch author, I want later registrations to supersede earlier ones with a warning, so that a targeted patch can replace a generic rule.
54. As a mod author, I want invalid API calls to return failure without throwing, so that a typo does not prevent the game from loading.
55. As a mod author, I want the compatibility API stable from 0.1.0 onward, so that routine updates do not break integrations.
56. As a compatibility tester, I want a diagnostic function that explains qualifying items, classification evidence, selected profile, settings, and suppression state, so that misclassification can be reported precisely.
57. As a player, I want diagnostics opt-in and normal logs quiet, so that routine play is not spammed.
58. As a player, I want classification work cached, so that the cosmetic effect has no noticeable performance cost.
59. As a player using a movement overhaul, I want best-effort cadence rather than a false compatibility guarantee, so that limitations are communicated honestly.
60. As a player, I want the package to work as a manual install, so that Steam Workshop is not required.
61. As a Workshop user, I want a correctly structured package, so that installation and updates follow Project Zomboid conventions.
62. As a Workshop visitor, I want accurate Build 42, Audio, Realistic, Weapons, and QoL tags, so that the mod is discoverable and correctly described.
63. As the publisher, I want the initial Workshop metadata set to unlisted, so that the listing can be checked before a public launch.
64. As the publisher, I want a minimal text-only preview image, so that Workshop requirements are met without expanding the project into illustrated artwork.
65. As a reader, I want English interface text, so that the first release is understandable.
66. As a translator, I want all visible strings stored in translation resources, so that another language can be added without code changes.
67. As a player or mod author, I want a README and compatibility guide, so that installation, settings, limitations, and integration are clear.
68. As a release reader, I want a changelog, so that version differences are easy to understand.
69. As an asset reviewer, I want a provenance ledger, so that every source recording's redistribution rights can be verified.
70. As a downstream developer, I want the code under MIT, so that fixes and compatibility work can be reused.
71. As an audio reuser, I want the original composites under CC BY 4.0, so that reuse terms and attribution are clear.
72. As the author, I want ambiguous or undocumented audio sources rejected, so that release convenience never overrides licensing certainty.
73. As a tester, I want representative vanilla handgun and long-gun cases, so that both profiles are validated in Build 42.
74. As a tester, I want at least one real third-party firearm smoke test, so that automatic mod compatibility is demonstrated beyond synthetic fixtures.
75. As a tester, I want suppression and priority combinations covered, so that edge cases do not create duplicate or incorrect playback.
76. As a tester, I want automated logic checks, package validation, and an in-game listening pass, so that both deterministic behavior and subjective audio quality are assessed.
77. As the author, I want macOS documented as the initial tested platform, so that untested platform claims remain honest.
78. As a prospective multiplayer user, I want multiplayer documented as expected but unverified, so that the absence of v0.1.0 multiplayer testing is explicit.
79. As the release owner, I want cadence, realism, and mix approved in-game before declaring 0.1.0 release-ready, so that code completion alone does not ship poor audio.
80. As the release owner, I want Steam publishing kept separate from package production, so that no external publication occurs without an explicit action.

## Implementation Decisions

- The public mod name is **Gun / Firearm Rattle SFX**. The stable internal namespace, mod ID, settings prefix, sound prefix, and compatibility namespace are `GunFirearmRattleSFX`. The author string is `timtim`; the initial version is 0.1.0.
- The runtime target is Project Zomboid Build 42. Compatibility is advertised for Build 42 generally, with 42.20.2 recorded as the tested baseline. Later 42.x revisions are not hard-blocked.
- The mod is entirely client-side. It contains no server scripts, network messages, replicated state, or world-noise emission. Nearby human players and zombies cannot hear or react to its custom sounds.
- v0.1.0 supports one local player. Local split-screen listener separation is not supported.
- The runtime is divided into a thin Project Zomboid adapter and one high-level Foley decision engine. The adapter gathers the local-player snapshot, invokes the engine, and applies the returned playback decision. The engine owns classification, priority, suppression, cadence, variation, and gain decisions.
- A player snapshot includes qualifying held and attached items, locomotion state, distance traveled, aiming and special-action state, hearing traits, global settings, cached equipment state, last sample, active-playback state, cadence history, and a controllable random source.
- The decision engine produces either a named suppression reason or a playback decision containing firearm profile, sample choice, calculated gain, and calculated pitch.
- Only firearms held in either hand or visibly attached to the character qualify. An inventory-only firearm does not qualify.
- Automatic firearm recognition first uses Build 42's firearm tag and gun-specific metadata. Non-firearm ranged weapons are explicitly excluded.
- Legacy recognition requires multiple gun-specific signals, such as ranged status combined with ammunition and firearm or reload metadata. Ranged status alone never qualifies.
- Firearms classify as handgun or long gun from attachment type and other gun metadata. If a firearm is tagged but lacks recognizable class metadata, two-handed status or weight of at least 2.5 selects long gun; otherwise it selects handgun. A one-time diagnostic warning records fallback use.
- Weapon condition, loaded state, magazines, suppressors, and other installed weapon parts do not alter classification or audio in v0.1.0.
- When several firearms qualify, only one profile may play. Priority is attached long gun, held long gun, attached handgun, then held handgun. Items at the same effective priority do not layer.
- Equipment classification is cached. It is refreshed by known equipment changes where available and by a fallback scan no more than four times per second. A new loadout must affect the next eligible movement step.
- Standard grounded non-aiming crouch-walk, walk, jog, sprint, and injured locomotion qualify. Actual distance traveled drives cadence so slowed movement naturally produces fewer eligible steps.
- Idle, aiming, vehicles, vaulting, climbing, falling, getting up, and other special actions are suppressed. Corpse dragging, large-animal carrying, heavy-object carrying, and other alternate locomotion are also suppressed.
- Aiming suppresses the entire custom effect, including Foley from other attached firearms, because Build 42 already supplies audio for aiming movement.
- Equipping, drawing, attaching, detaching, and holstering do not trigger custom sounds.
- Footfall timing is perceptual rather than animation-event exact. The engine accumulates traveled distance and uses locomotion-aware cadence calibrated against vanilla Build 42 movement. Movement overhauls receive best-effort support.
- Playback is intermittent and step-aligned. The initial frequency configuration is: Very Low at 20% with a forced accent after eight missed eligible steps; Low at 35% after five; Normal at 50% after three; High at 70% after two; Very High at 90% after one.
- A four-sample pool exists for each profile. Immediate sample repeats are prohibited. If a prior custom accent is still active, the next accent is skipped rather than overlapped or cut off.
- Per-play randomization is bounded to approximately plus or minus 3% pitch and plus or minus 10% gain.
- Initial relative movement gain is 45% crouching, 65% walking, 85% jogging, and 100% sprinting. Handguns use 80% relative profile gain and long guns 100%. Held firearms use 55% relative carry gain and attached firearms 100%.
- Gain factors multiply before the user's volume setting and bounded random variation. The final mix is tuned so the default remains below footsteps, combat, weapon handling, and environmental threats.
- Deaf suppresses playback. Hard of Hearing applies an additional 60% gain factor. Keen Hearing leaves close self-Foley unchanged.
- Build 42's native Mod Options system provides three global client controls: enabled, volume, and frequency. Defaults are enabled, 50% volume, and Normal frequency. Changes apply by the next eligible step and persist across saves and servers.
- The sound set contains eight original composites: four handgun and four long-gun variants. Each is mono 44.1 kHz OGG, approximately 150–350 milliseconds, with a clean dry tail.
- Handgun composites emphasize restrained holster leather or nylon plus faint metal or polymer movement. Long-gun composites emphasize sling and fabric tension plus slightly heavier buckle, stock, or hardware contact. Samples must not resemble firing, reloading, chambering, safety manipulation, or other weapon handling.
- Source recordings must have explicit CC0 or public-domain grants and stable provenance. Sources with unclear licensing are rejected. Composites are original edited works with documented source and transformation information.
- No custom indoor, outdoor, weather, or floor-material variants are included.
- The stable compatibility API exposes one exact-item registration operation under the mod namespace. It accepts a full item ID and one of three classifications: handgun, long gun, or silent.
- Explicit registrations have absolute precedence over automatic classification. Conflicts use last-registration-wins and produce one diagnostic warning. Valid registrations return success; invalid IDs or classifications return failure and warn without throwing.
- Public compatibility names and classification values are backward-compatible from 0.1.0 onward; future changes should be additive.
- The diagnostic operation under the mod namespace reports current qualifying items, classification evidence, selected profile and carry state, settings, and active suppression reason. It is invoked explicitly from the Lua/debug console and creates no permanent UI setting.
- Malformed external item data keeps gameplay running and leaves the item silent. Warnings are deduplicated by item type.
- All player-visible strings are English in v0.1.0 and stored in translation resources.
- Runtime code performs no full inventory scans, network work, or avoidable per-tick allocation. Only lightweight local movement tracking may run each client tick.
- The distribution provides both a manual-install mod folder and a Workshop-ready wrapper from the same authoritative source layout.
- Workshop metadata defaults to unlisted and uses the official Build 42, Audio, Realistic, Weapons, and QoL tags.
- Artwork is limited to a required 256-by-256 text-only Workshop preview. No illustrated artwork or separate custom in-game icon is part of v0.1.0.
- Documentation includes installation and configuration instructions, compatibility API guidance, limitations, troubleshooting, an in-game test checklist, a changelog, a Workshop description, provenance, and license texts.
- Lua code is MIT licensed. Original audio composites are CC BY 4.0 licensed.
- The source tree remains authoritative; local game testing uses a clean generated copy in the Project Zomboid mods directory.
- Steam Workshop publication is not part of delivery. The package and listing text are prepared, but upload requires a separate explicit action.

## Testing Decisions

- Automated tests use one highest practical behavioral seam: the Foley decision engine. Tests provide a complete local-player snapshot and controlled random input, then assert the externally observable suppression or playback decision. Tests do not assert internal helper calls, cache layout, loop structure, or other implementation details.
- The Project Zomboid adapter remains thin and is not duplicated across many mocked seams. Static validation verifies client-only placement, metadata, resources, translations, sound definitions, and the absence of server, network, and world-noise operations.
- Classification tests cover vanilla firearm tags, handgun and long-gun metadata, legacy multi-signal detection, non-firearm ranged exclusions, ambiguous tagged fallbacks, malformed metadata, exact overrides, silent overrides, conflicting registrations, and invalid API input.
- Selection tests cover held and attached items, inventory-only exclusion, duplicate two-hand references, all priority combinations, and the guarantee that only one profile is selected.
- Suppression tests cover disabled settings, no qualifying firearm, idle, aiming, vehicles, special actions, alternate locomotion, Deaf, active prior playback, and malformed external items.
- Cadence tests cover crouch, walk, jog, sprint, injury-reduced speed, intermittent probability at each named level, forced maximum silent streaks, movement starts and stops, unrealistic position jumps, and the no-overlap rule.
- Variation tests use a deterministic random source to verify sample non-repetition, pitch bounds, gain bounds, and stable playback decisions without asserting a specific production random-number implementation.
- Gain tests verify the multiplication of locomotion, firearm profile, carry state, hearing trait, global volume, and bounded random variation. They verify relative ordering rather than subjective loudness.
- Settings tests cover defaults, global persistence contract, legal ranges, named frequency values, live application, and enable/disable behavior.
- Diagnostic tests verify that reports expose classification evidence and suppression reasons, warnings are deduplicated, and normal play remains quiet.
- Performance checks verify that classification scans are rate-limited to four per second absent an equipment event and that the decision engine does not scan full inventories or perform networking.
- Package checks validate the Build 42 structure, mod metadata, version and author strings, manual-install layout, Workshop wrapper, unlisted visibility, official tags, required text-only preview dimensions, translation resources, licenses, and provenance records.
- Audio checks validate eight unique mono 44.1 kHz OGG files, duration bounds of approximately 150–350 milliseconds, clean tails, no clipping, and successful reference from sound definitions.
- The human in-game matrix uses `Base.Pistol` as the vanilla handgun reference and `Base.Shotgun` as the vanilla long-gun reference. It covers held, attached, mixed priority, all supported locomotion states, aiming suppression, idle and excluded actions, settings changes, and hearing traits.
- A real third-party smoke test uses `Base.Pistolm93r` from the installed Vanilla Weapons Plus – Gunworks Edition environment. That mod remains optional and is not declared as a dependency.
- The author's subjective listening pass judges cadence, realism, repetition, and mix beside vanilla footsteps and ambience. Audio and code are evaluated together rather than gating integration on isolated samples.
- v0.1.0 is code-complete after automated tests, package checks, installation, and clean log inspection. It is release-ready only after the author approves the in-game listening pass.
- macOS with Project Zomboid 42.20.2 is the tested platform. Windows and Linux are expected to work from the platform-independent package but are initially unverified.
- No multiplayer session is tested for v0.1.0. Static checks establish that the implementation is client-only and sends no network or world-noise state. Documentation labels multiplayer as expected but unverified.
- There is no existing project test suite or prior implementation to reuse. The single decision-engine seam is therefore the new highest-level behavioral seam, while the installed Build 42 game files and official mod structure are the integration reference.

## Out of Scope

- Build 41 compatibility or a dual-version package.
- Server installation, server scripts, network synchronization, or sound audible to other players.
- Zombie attraction, stealth penalties, world-noise emission, or any gameplay balance change.
- Formal multiplayer validation in v0.1.0.
- Local split-screen support.
- Melee weapons, backpacks, armor, keys, loose inventory contents, and other non-firearm equipment categories.
- Bows, crossbows, slingshots, and non-firearm ranged weapons.
- Multiple simultaneous firearm profiles or layered accents.
- Audio based on weapon condition, ammunition state, magazines, suppressors, or installed parts.
- Custom firing, reload, chambering, draw, holster, attach, detach, or other handling sounds.
- Custom Foley during aiming movement.
- Special-action and alternate-locomotion Foley, including vaulting, climbing, falling, getting up, corpse dragging, animal carrying, and heavy-object carrying.
- Environment-specific indoor, outdoor, weather, or floor-material sound variants.
- Exact synchronization through private animation events or guarantees for custom movement animations.
- Arbitrary callback-based compatibility rules; v0.1.0 overrides use exact item IDs only.
- A user-facing diagnostic menu or persistent debug mode.
- Non-English translations in the initial package.
- Illustrated Workshop artwork or a custom in-game icon.
- Automatic Steam Workshop publication, public visibility, or account operations.
- A dedicated external server test.

## Further Notes

- The local repository is currently empty, has no commits, and has no configured remote. Existing backup and image files remain untouched and untracked; only the mod directory is intended for version control.
- Planned implementation work uses the dedicated branch `codex/gun-firearm-rattle-sfx` and remains uncommitted until the complete 0.1.0 diff and validation results are ready for explicit approval.
- The project source location is the agreed `GunFirearmRattleSFX` directory inside the existing Extensions workspace. The game mods folder receives a clean test copy rather than becoming the source of truth.
- The connected issue tracker was not available during spec synthesis: the local repository has no remote, the connected GitHub app has no installed account or accessible repositories, and the command-line GitHub credential is invalid. This document is formatted as the issue body and is ready to publish once a repository target and working tracker connection exist.
