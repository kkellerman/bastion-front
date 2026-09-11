# Changelog

## Material and Procedural Tree Density Pass - 2026-09-11

- Trialed replacing procedural tree visuals with low-poly CC0 pine models
  (Quaternius); reverted after review found the stylized look a worse fit than
  the existing procedural trees.
  Densified the procedural trees instead: more branches with per-branch angle/
  length/droop jitter, sub-twig clusters and a third off-axis leaf card per twig
  in `tools/build_forest_assets.gd`, and a denser hand-drawn needle atlas in
  `tools/build_needle_atlas.gd`. Same generation pipeline, meshes and materials;
  no collision, navigation or placement changes. Forest primitive count rises
  from roughly 4.16M to 4.71M at the High preset; Low/Auto remains well above
  100 FPS on the Radeon 860M reference machine.
- Replaced the hand-drawn needle atlas with photographic CC0 fir twig maps (Poly
  Haven Fir Tree 01 textures only; its 8M-triangle mesh is unusable in real time).
  `needle_branch.gdshader` now carries a real normal map instead of flat shading,
  so foliage participates in the same PBR lighting as the ground and concrete.
  Leaf cards map to individual sprig sub-rectangles within the atlas and flip
  randomly, and carry a crown-depth vertex value the shader uses to darken cards
  deep inside the canopy.
- Fixed a severe forest frame-rate regression found while making that change: the
  generated atlas imported uncompressed and without mipmaps, which on the scene's
  most overdrawn surface cost roughly 46 to 7 FPS. Enabling VRAM compression and
  mipmaps restored it; the forest now measures 38 FPS at High and 138 FPS at
  Low/Auto on the Radeon 860M reference machine.
- Fixed low-hanging canopy geometry: the added branch/droop jitter above could
  put foliage as low as roughly 0.5-0.9 m, well under standing eye height
  (1.65 m) and blocking sightlines/aim near the trunk. Raised the branch base
  clearance floor (2.4 m to 3.4 m near the trunk) and reduced downward jitter/
  droop specifically for low branches; verified lowest baked foliage vertex is
  now 2.5-2.7 m, above the previous unjittered baseline.
- Added three CC0 Poly Haven texture sets (worn metal, worn planks, rough linen)
  and wired them into command-post furniture/fixtures, sandbags/camouflage scrim
  and mission crate dressing in place of flat procedural colors.
- Strengthened the procedural worn-surface shader's normal detail and increased
  cylinder segment counts to remove visible faceting on rods/pipes/barrels.
- Fixed a dialogue leak where a killed actor's in-progress voice line and subtitle
  continued playing to completion instead of stopping immediately on death.

## Constrained Operations and Forest World Presentation - 2026-09-11

- Added seven authored zone resources with sixteen bounded options and deterministic
  seed selection. Patrols, supplies, tree visuals, foliage/debris and fortification
  kits vary without generating arbitrary terrain or moving objectives/nests.
- Added menu seed entry/New Operation, guarded staging F3 regeneration and persistent
  F9 seed/zone display. Death and faction reloads retain the seed; checkpoints store
  it and reject cross-operation restores.
- Added optional eastern-track log restriction and two committed navigation bakes.
  Restricted baking to the playable rectangle and used 25 cm mission voxels / 50 cm
  navigation clearance to keep long paths within Godot's default search budget.
  Fixed two existing cover markers embedded in trench collision.
- Added one reusable cold-overcast atmosphere resource, coherent sun direction,
  layered fixed clouds, softer haze and balanced exposure. Replaced a trigonometric
  noise hash that produced visible cloud-cell seams on the test GPU. No random weather.
- Revised original tree crowns/LODs, clustered ground dressing, offset ground-texture
  blending, moss/mud/gravel masks, detail normals and worn timber/metal variation.
- Replaced the monolithic horizon batches with spatial MultiMesh groups; added
  smooth closed banks, irregular plantings and a winding rear rendezvous trail.
  Auto/Low retains atmosphere and silhouettes with bounded distance/density.
- Added multi-seed/faction placement, full-route capsule, checkpoint and operation
  input regressions; extended mission walking coverage to the restricted flank.
  Captured Auto/High comparisons and documented validation/performance results in
  `docs/OPERATION_VARIANTS_VALIDATION.md`. Reused original/credited CC0 assets only.

## Weapon Handling, Operated Nests and Mission Perimeter - 2026-09-10

- Added shared handling resources: camera kick/recovery, bounded automatic climb,
  lateral drift, movement/turn inertia, breathing and stance transitions. Reduced
  motion attenuates these effects; existing movement and ammunition rules remain.
- Added timer-synchronized magazine and charging-handle presentation with moving
  support-hand contact. Reload ammo still transfers once at completion.
- Faction resources choose MG42/M1919 defensive scenes. Deterministic operator
  placement and skeletal grip targets replace the idle soldier beside the gun.
  Mounted combat enforces hostility, range, sight, muzzle obstruction and both
  angular limits. Dead/disabled gunners release capture and their callbacks.
- Added infantry acceleration/deceleration, shallow combat crouch with independent
  capsule/vision height, ground-sampled foot adaptation and acceleration lean.
- Added collision-matched perimeter berms, two batched forest backdrop layers and
  a marked rear rendezvous gate. Unintended escapes recover to safe ground; invalid
  falling positions no longer replace checkpoints.
- Preserved softened footsteps and the user's -26 dB gain. Revalidated existing
  actor/audio/dialogue retirement, ambience, effects and downed-camera behavior.
- Enlarged dust/smoke cloud envelopes for readable explosions without increasing
  particle counts; disabled emplacement physics now retires its flash immediately.
- Added focused handling/faction-nest/perimeter and locomotion regressions plus High
  rendered evidence. No external assets, plugins, dependencies or new gameplay modes.

## Quiet Footsteps and Mounted Aiming - 2026-09-10

- Replaced sharp footstep transients with soft heel/scuff envelopes on dirt, wood,
  concrete and metal. Lowered playback from -18 to -30 dB, shortened range to 12 m,
  and filtered harsh high frequencies. Generic steps reuse the softened dirt cue.
- Added right-mouse aiming to M1919/MG42 emplacements: closer sight-aligned camera,
  56-degree aim FOV, aimed spread and smooth release. Dismount/death restore the
  camera and clear held input; mouse traverse and firing arcs remain intact.
- Added native input/audio regression for all three placements, firing while aimed,
  release/dismount cleanup, footstep waveform energy and soft attack envelopes.

## Combat Feedback, Soundscape and Death Polish - 2026-09-10

- Closed disabled-parent dialogue and direct scheduler/hitscan callback bypasses;
  cancelled queued casualty lines and active subtitles when their actor retires.
  Actual death no longer starts a new line. Existing audio tails may finish.
- Added shared actor-owned layered muzzle flash/light/smoke/sparks, aligned infantry
  effects to held weapon sockets, and immediate invalid-actor flash cleanup.
- Replaced the expanding explosion sphere with bounded procedural fire, dust,
  lingering smoke, surface-colored debris, pressure dust, light and scorch marks.
  Kept projectile collision, damage falloff, cover and self-damage logic intact.
- Added distance-driven layered leg motion and aiming while retaining body clips;
  removed competing root flinch tweens. Added downed camera/weapon cleanup on death.
- Added rate-limited health-driven flesh/gear cues, NPC puffs and a subtle player
  damage vignette using original sound design; no gore or arcade hit markers.
- Fixed wind loop joins through overlap-add; added persistent staggered forest beds,
  positional radio static/hum/signals and independent ambience/comms/artillery gains.
  Artillery varies off-map location/pitch/timing and fades indoors. Scene, death and
  completion cleanup retire environmental playback. Existing settings are preserved.
- Added combat-feedback lifecycle regression and an all-seven-killed physical
  command-post walk, plus scripted rendered evidence. Updated old AI tests to enable
  actors when deliberately exercising live hearing/dialogue interfaces.


## Soldier Audio Investigation - 2026-09-10

- Confirmed neither faction has installed speech recordings; dialogue volume does
  not fix missing assets. See docs/VOICE_RECORDING_MANIFEST.md for recording hooks.
- Fixed infantry collision masks so living soldiers cannot occupy one another's
  bodies, obscuring the source of gunfire. Dead soldiers still release collision.
- Added an opt-in F9 mission audit showing soldier names through cover, positions,
  states, camera/cover relationship, recent combat sound sources, output device,
  bus levels and the separate off-map artillery setting. Disabled by default.
- Added infantry_separation_smoke.gd for converging actors, corpse clearance and
  the audit overlay. Mission checks found all seven soldiers above ground and
  outside static walls; patrols can legitimately follow and fire from behind.

## Targeted Audio, Graphics and Asset Polish - 2026-09-10

- Removed listener-following ambient rifle fire; optional low-pass off-map artillery
  is independently configurable and off by default. Guarded infantry/mounted attacks
  and audio/noise emission against dead/disabled sources; retained natural tails.
- Made missing English/German recordings explicit; added labeled non-speech audio
  diagnostics, automatic recording paths, actor-following spatial playback, priority
  death interruption and a production recording manifest. No speech is fabricated.
- Fixed settings/subtitle anchors that placed controls off-screen; added viewport
  containment checks and a fixed, visible settings return button.
- Added conservative hardware-aware Auto and persistent Low/Medium/High settings:
  resolution scale, shadows, fog, SSAO/SSIL, AA, vegetation, SSR and mip bias.
- Replaced solid tree leaves with an original needle atlas and branch cards; revised
  terrain, ground response, sandbags, camouflage, concrete edges, weapon furniture,
  sleeves/hands, heads, uniform surfaces and clouds. Batched static dressing.
- Rebuilt navigation with finer detail sampling to remove overlapping edges;
  added native audio/voice/graphics regression coverage and comparative captures.
- Exact voice status, remaining interim assets, measurements and validation:
  docs/POLISH_VALIDATION.md and docs/VOICE_RECORDING_MANIFEST.md.

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
