# Targeted audio, graphics and asset polish — 2026-09-10

Godot 4.7.2, typed GDScript. No new gameplay systems, plugins, dependencies or
external downloads. The main scene remains `scenes/ui/title_menu.tscn`.

## Ghost gunfire

The soundscape spawned `distant_fire` every 10–19 seconds at an offset of only
(30, 8, -45) metres from the current listener, with a large attenuation unit and
an outdoor gain of -13 dB. It ran independently of living enemies. This explained
gunfire apparently following the player after the local fight ended.

That rifle ambience is removed from playback. Optional distant artillery is off
by default, fixed at (180, 15, -300), at -22 dB outdoors / -30 dB indoors, through a
separate 700 Hz low-pass DistantCombat bus. F10 enables/disables it independently.
Wind, birds, bunker hum and real combat remain active. No global post-combat mute.

CombatAudio now rejects dead/disabled sources before hearing events and playback;
InfantryCombat and MountedWeapon also reject them before consuming ammunition or
dealing damage. Gunshot requests respect disabled handheld combat. Existing
one-shots finish naturally and belong to the scene; restarted scenes retire them.
Already-launched explosive projectiles remain valid independent of shooter death.
Cue/source metadata and cue_started make emission testable without relying on ears.

The native regression disables actors both by process mode and physics processing,
kills the rest, exercises direct and delayed stale attack calls, waits 21 seconds,
checks no new hostile cues/noise or residual local emitters, and verifies wind still
plays. It separately enables and verifies the distant channel.

## Voice status

Both faction recording dictionaries were empty. There was no sound to play; merely
connecting subtitles could not fix this. Missing slots are now explicit in settings
and subtitles. Opt-in, labeled original non-speech tones exercise real playback.
The final visual check also found that assigning absolute negative positions after
setting anchors had moved the settings/subtitle controls off-screen. They now use
anchor-relative offsets, with viewport-containment regression assertions. The
settings return button stays visible outside the scrolling options area.
Audio follows the actor, uses the correct bus and retires on scene teardown.
Death now interrupts combat lines instead of being swallowed by reload/hurt
cooldowns. Healing no longer falsely triggers the player's taking-fire event.

Native AudioEffectCapture tests verify nonzero Dialogue bus samples for all eight
combat categories in both factions, including correct language resource metadata,
cooldowns, supplied AudioStream slots and interior bus routing. Headless tests alone
cannot demonstrate audible output. No fake German or generated speech is present.
The exact remaining asset list is [VOICE_RECORDING_MANIFEST.md](VOICE_RECORDING_MANIFEST.md).

## Graphics

Startup logs Godot's renderer, adapter name/type and graphics API version. Available
VRAM budget is explicitly unknown: memory-use counters are not free VRAM. No shell
hardware inventory, name-based speed guess, or claim of measured capability is used.
Auto is a conservative starting recommendation: integrated/unknown/virtual/CPU and
fallback renderers select Low; Forward+ discrete adapters select Medium, never High
solely because they are discrete. Actual performance still varies across machines.

F10 offers Auto/Low/Medium/High and an explicit auto-detect action. The selected
choice persists in `user://settings.cfg`; ordinary startup respects manual choices.
First launch and older configs without the new key use Auto. Normal UI shows a short
recommendation; raw adapter information stays in diagnostic logs.

| Setting | Low | Medium | High |
| --- | --- | --- | --- |
| Internal resolution scale | 80% | 100% | 100% |
| Directional shadow distance / atlas | 32 m / 1024 | 45 m / 2048 | 65 m / 4096 |
| Shadow splits / filter | 2 / soft low | 4 / soft medium | 4 / soft medium |
| Volumetric fog | Off | Off | On |
| SSAO / SSIL | Off / Off | On / Off | On / On |
| MSAA / FXAA | Off / On | Off / On | 2x / Off |
| Understory density / range | 45% / 26 m | 70% / 36 m | 100% / 45 m |
| Tree far-tier range | 65 m | 75 m | 85 m |
| Screen-space reflections | Off | Off | On, 32 steps |
| Texture mip bias | +0.5 | 0 | -0.25 |

Existing material mipmapped/anisotropic filtering remains; presets change sampling
bias, not texture import dimensions or disk assets. Sky reflections remain at every
tier. Forward+-specific effects are gated off on other rendering methods. Low keeps
the same geometry/collision, light levels and exposure; it does not obscure the scene.

## Asset changes

- Original 512×1024 spruce needle atlas and alpha-cutout branch cards replace solid
  diamond foliage. Irregular spruce and taller, open-crown variants retain separate
  near/far meshes. Foliage mesh resources shrink from ~875 KB to ~95 KB per near tier.
- More pronounced, collision-matched forest hummocks; vegetation and trunks follow
  height. Main road, range, fortification and flank routes retain their level paths.
  Mud ruts wander slightly, include tread breakup, and use wet roughness response.
- Squared, creased, staggered sandbags; sagging rope/scrim camouflage; irregular
  chipped concrete edges; grain/patina wood and equipment materials. Static dressing
  is batched by material to reduce draw calls. Existing collision envelopes remain.
- P38's exposed barrel/shorter slide, thinner magazines and a segmented curved StG
  magazine; grain replaces bark on gun furniture; worn metal replaces flat surfaces.
  Sleeves/hands have tapered oval sections, folds and articulated finger segments.
- Original skinned heads replace the blank donor heads: jaw, cheeks, nose, sockets,
  lips, brows and surface variation. Uniform dirt/fabric variation and subtle head/
  hip animation accompany the existing shared rig. Muzzle flashes are smaller/shorter.
- Layered cloud shapes and directional cloud lighting replace the flatter sky.
  Exposure, fog density and overall grading were not darkened to conceal assets.

These are visibly interim authored assets. They improve specific silhouettes and
surface cues but **do not achieve finished photorealism**. Low-detail donor tailoring,
hands, procedural heads, foliage aliasing/LOD transitions, straight blockout layout,
approximate equipment and synthetic effects still need professional art/audio work.

## Navigation and regression

The revised relief exposed two non-manifold shared edges in the sparse Recast detail
bake. Denser detail sampling (0.1 m world spacing) and 3 m contour-edge limits removed
the topology conflict; the final bake has 5,792 polygons. Warnings remain enabled.
Physics uses the full terrain collision. See Godot's [NavigationMesh properties](https://docs.godotengine.org/en/stable/classes/class_navigationmesh.html)
for sampling units. Mission traversal and the alternate-route checks exercise the bake.

Validation commands (from the repository):

Result: editor import plus all nine smoke suites passed with zero failures. Native
menu-to-mission launch, physical extraction/restart and active combat were exercised.
The combat capture records player health 76 while the infantry is in ATTACK state.
The new test also checks the bake for non-manifold shared edges.

```powershell
godot --headless --path . --editor --import --quit
godot --path . --script res://tests/movement_smoke.gd
godot --path . --script res://tests/weapon_smoke.gd
godot --headless --path . --script res://tests/infantry_smoke.gd
godot --headless --path . --script res://tests/combat_prototype_smoke.gd
godot --headless --path . --script res://tests/defensive_mg_smoke.gd
godot --path . --script res://tests/mission_flow_smoke.gd
godot --path . --script res://tests/presentation_smoke.gd
godot --headless --path . --script res://tests/fidelity_smoke.gd
godot --path . --script res://tests/polish_smoke.gd
godot --path . --script res://tests/presentation_capture.gd -- --preset=auto
godot --path . --script res://tests/presentation_capture.gd -- --preset=high
godot --path . --script res://tests/character_capture.gd
```

## Performance and captures

Radeon 860M integrated, Vulkan Forward+, 1280×720 output, VSync disabled for these
samples. Auto selects Low (1024×576 internal). Each fixed viewpoint warms 100 frames
then times 90 frames; AI is frozen to compare rendering. These are average static
samples, not combat minima, percentiles, or cross-hardware guarantees.

| View | Auto FPS | Explicit Low FPS | High FPS |
| --- | ---: | ---: | ---: |
| Forest | 109.0 | 112.5 | 38.5 |
| Bunker approach | 215.8 | 193.1 | 64.0 |
| Radio room | 209.8 | 217.8 | 63.0 |
| Operations room | 224.2 | 265.8 | 69.2 |

Auto and Low apply identical settings on this adapter; the separate runs illustrate
run-to-run variation rather than a different quality level. Earlier VSync-capped
captures in FIDELITY_VALIDATION.md are not directly comparable to these uncapped runs.

Screenshots: [High forest](screenshots/polish_high_forest.png),
[Auto/Low forest](screenshots/polish_auto_forest.png),
[bunker](screenshots/polish_high_bunker.png),
[radio](screenshots/polish_high_radio.png),
[operations](screenshots/polish_high_operations.png),
[combat](screenshots/polish_combat.png), [characters](screenshots/polish_characters.png),
[settings](screenshots/polish_settings.png).

The restricted validation environment's existing root-certificate-store diagnostic
remains unrelated to local gameplay. No new asset downloads require a license review;
existing third-party assets and their CC0 licenses are listed in
[ASSET_ATTRIBUTION.md](../ASSET_ATTRIBUTION.md).
