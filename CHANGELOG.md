# Changelog

## Character, Voice, Forest and Combat Fidelity - 2026-09-10

- Added shared 17-bone Allied/German character rigs, nine animation clips,
  AnimationTree hooks, modular helmets/equipment and held-weapon sockets. Retargeted
  nisu's CC0 soldier body; retained source/license records and original faction gear.
- Added faction sleeves/hands to all seven viewmodels with resource-defined support
  poses, draw/reload motion and reduced-motion support. Assets remain interim.
- Added English/German combat and briefing resources, localization keys, durations,
  spatial/reverberant recording playback, subtitles and actor/category/global limits.
  All eight combat events are routed; recording slots remain explicitly silent.
- Added overcast cloud sky, denser varied tree crowns, actual distant mesh tiers,
  randomized collidable trees, moss and shallow collision-matched terrain relief.
  Rebuilt mission navigation to 1,446 polygons.
- Added bounded impact debris/decals, muzzle smoke, explosion dust, directional
  near-miss response and rigged hurt/death presentation.
- Added opt-in encounter coordination: shared reports, bounded searches, real-cover
  evaluation, short supported flanks and friendly muzzle obstruction checks. Sight
  still gates every attack; original sandbox timing and controller remain intact.
- Added east supply/flank route, compact objective UI, before-bunker/document
  checkpoints and F10 persistent accessibility/audio/graphics options.
- Added fidelity regression and character/combat captures; reran existing import,
  movement, weapons, infantry, combat, mounted-gun, mission and presentation suites.
  Performance samples and commands: docs/FIDELITY_VALIDATION.md.

## Forest / Command Post Visual and Audio Pass - 2026-09-10

- Added a live BASTION FRONT title menu, Allied/German test starts, controls and
  asset credits; the mission remains directly runnable.
- Integrated four verified CC0 Poly Haven photographic PBR texture sets with
  provenance in ASSET_ATTRIBUTION.md. Added original branched tree meshes, roots,
  grass/ferns/shrubs/litter, rocks/logs, muddy trail shading and distance culling.
- Dressed fortifications with individual sandbags, timber, camouflage strips,
  wire and signs. Added weathered bunker walls, maps, communications equipment,
  office furniture, records cabinets, crates, lamps and conduit.
- Tuned ACES, SSAO/SSIL, volumetric haze, shadows and antialiasing.
  Profiled and reduced excessive foliage geometry/shadow cost.
- Improved all carried weapon silhouettes and both mounted guns, including beveled
  surfaces and small details; added a German equipment mannequin and held models.
- Added original layered audio assets, material impacts/steps, outdoor ambience,
  distant combat and bunker acoustics. Added correct German subtitle placeholders
  with separate recording slots; no synthesized speech or external recordings.
- Preserved combat/controller behavior and existing tests. Rebaked navigation to
  1,236 polygons around office furniture. Added menu/presentation checks and captures.
- Art/audio remain interim: final rigged characters/hands, authentic recordings,
  sculpted terrain and production foliage LODs are still required.

## Combat Prototype and First Mission Blockout - 2026-09-10

- Followed the explicitly expanded combat/faction/mission scope; retained the
  authoritative specification and original regression sandbox.
- Added P38, Thompson, MP40, StG 44, Bazooka and Panzerfaust alongside M1911 using
  shared weapon resources, switching, individual magazines and pooled reserves.
- Added Allied/German loadouts and hostility, faction stations, ammo/health/grenade
  supplies, physics grenades/rockets, cover-aware explosions and self-damage.
- Added usable M1919 and MG42 emplacements, constrained aiming, belts/reloads,
  gunner control and capture after gunner death.
- Added primitive viewmodels, recoil/flash/impact feedback, spatial audio routing
  with original synthesized sounds, footsteps and final-asset hooks.
- Preserved enemy sight/memory; added optional hearing, varied weapons, movement
  and reaction timing, short attack bursts and visible hit reactions.
- Added the default Forest Command Post mission: range, forest trail, patrols,
  fortifications, trench approach, defended MG42, bunker rooms, documents and rear
  extraction. Committed a 1,216-polygon navigation bake.
- Added combat, defensive MG and physical mission-flow suites; preserved and reran
  movement, weapon and infantry checks, editor import and Vulkan launch.
- Next phase: art, sound, animation, encounter pacing and level polish.

## Requested Milestone 3 - Infantry Prototype - 2026-09-10

- Followed the user's explicit enemy-prototype scope; the specification numbers
  basic AI as Milestone 4 and faction configuration as Milestone 3. The design
  specification is unchanged and no faction framework was introduced.
- Added one reusable CharacterBody3D infantry scene with separate vision, motor,
  combat and state-machine scripts, plus a German placeholder visual and SMG data.
- Added idle, patrol, alert, chase, attack, hurt and death; 24 m / 100-degree vision,
  occlusion checks, four-second last-seen memory, and NavigationAgent3D movement.
- Baked a 669-polygon navigation mesh from static sandbox collision, including the
  target board and tree trunks; added a repeatable Godot bake script.
- Generalized DamageReceiver to attach to static or moving collision bodies and
  shared hitscan code between enemy and player. Existing pistol ammo/controls and
  movement/mouse-look scripts remain intact.
- Added player health, a minimal death/restart prompt, and enemy death that disables
  collision and combat. Added an infantry integration suite and reran regressions.
- No squad behavior, cover selection, melee, grenades, dialogue or final art.

## Milestone 2 - First Allied Pistol - 2026-09-10

- Added shared `WeaponData`, per-instance `WeaponBase` ammo/timers, and a separate
  hitscan component; future weapon configuration does not require faction branches.
- Integrated an M1911 placeholder via a camera-mounted weapon rig without changing
  the existing movement or mouse-look scripts.
- Added semi-automatic fire, a 300 RPM limit, 7-round magazines, 35 reserve rounds,
  1.8-second reloads, muzzle flash, viewmodel recoil, basic aiming and impact markers.
- Added crosshair, ammo/reload HUD and a 100-health damage target that resets three
  seconds after destruction; damage uses reusable health and receiver components.
- Verified mechanics headlessly, input/rendering under Vulkan and the existing
  movement regression suite. Added `tests/weapon_smoke.gd`.
- Scope is the requested first pistol. Additional weapons, projectile behavior,
  faction logic, enemy AI and final assets remain deferred.

## Milestone 1 - Movement Sandbox - 2026-09-10

- Created Bastion Front as a Godot 4.7.x Forward+ / Vulkan project with the
  specification's directory layout and `scenes/main.tscn` as the launch scene.
- Added a reusable typed first-person controller with WASD, mouse look, sprint,
  jump, gravity, floor snapping, crouch with standing clearance, and mouse
  capture/release on Escape, click and focus loss.
- Included the specification's interaction ray scaffold without interaction logic.
- Added an editable outdoor forest blockout, shared placeholder materials,
  collidable conifers, bounded ground, jump blocks, ramp and low passage.
- Added usage documentation and executable movement/scene smoke checks.
- Stopped at Milestone 1; no later gameplay systems or final artwork added.
