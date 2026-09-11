# Bastion Front

A playable WWII combat and first-mission presentation slice for **Godot 4.7.x**, typed
GDScript, Forward+ / Vulkan. `wolf_like_godot_starter.md` remains authoritative.
This pass follows the explicitly expanded combat/mission scope; the specification's
milestone numbering is unchanged. The visual pass combines CC0 photographic PBR
materials with original interim environment, equipment and sound assets.

## Replayable operations and fixed forest atmosphere

The menu now accepts an **Operation Seed** and provides **New Operation**. Choose
Allied or German to launch that layout. **F3** generates and loads a new operation
while still in staging, before firing, throwing a grenade, or departing; it is
unavailable while mounted.
Returning to staging after departure does not unlock it. **F9** shows the active
seed, selected zone options and existing soldier/audio audit. The default **1944**
keeps the original encounter and supply positions; **1** exercises the restricted
flank, and **73** offers a different open-flank operation. Direct launch example:

```powershell
godot --path . res://scenes/missions/forest_command_post.tscn -- --operation-seed=1
```

Seven native resource zones contain sixteen authored options: staging, forest
approach, patrol encounters, fortification, bunker, documents and extraction.
Local seeded generators select patrol/supply anchors, small dressing kits, tree
crowns/orientation and bounded vegetation patches. The eastern track can have a
log obstruction along one edge; a traversable lane remains beside it. Fortification
log and crate kits share fixed collision envelopes. Required routes, doors,
objectives, gun positions and terrain collision remain authored. Two committed
navigation meshes cover the open/restricted track; no runtime rebake is needed.
Seeds persist through death, checkpoint restore and faction switching. New seeds
clear checkpoints, and saved checkpoints reject a different operation seed.

There is one fixed **cold overcast** resource, with layered clouds, sun-aligned
sky lighting, soft haze and balanced interior exposure. No weather selector or
random weather was added. Ground shading blends offset texture samples, moss,
mud/ruts, gravel and detail normals. Bark/concrete retain their credited CC0 maps;
timber/metal gain broad wear variation. Revised tree crowns share their branch
skeleton with lower-detail meshes. Irregular planted banks, softened rock groups
and a winding trail beyond the extraction gate replace the sparse backdrop.

The horizon uses spatial MultiMesh groups with bounded density and culling.
Auto/Low keeps the same weather and mission silhouettes with fewer plants,
shorter shadows and cheaper fog. See [operation validation](docs/OPERATION_VARIANTS_VALIDATION.md)
for measured before/after frame times, seed coverage, screenshots and limitations.
On the tested Radeon 860M, seed-1944 warmed forest frames improved from 8.39 to
7.50 ms on Auto and 27.14 to 23.21 ms on High. All fifteen retained suites, the
two new operation suites and the restricted-flank walkthrough passed. These are
static presentation measurements, not worst-case combat frame-rate guarantees.
All additions use original work and existing credited assets; no downloads.

## Character, voice, forest and combat fidelity

The handling/nest/perimeter iteration adds resource-driven camera recoil with
bounded burst climb/recovery, turn and movement inertia, breathing sway, and
aim/crouch/sprint transitions. Reload presentation follows the existing ammo timer:
grip (0–18%), magazine removal (18–45%), insertion (45–78%), chamber action
(78–100%), then the single ammo transfer. The support hand follows these parts;
the trigger hand remains attached to the carried weapon.

Faction resources now select the defensive mounted scene: Allied play faces a
German MG42 operator; German play faces an Allied M1919 operator. Gunners are
placed at authored operating points, use grip-target arm posing, and run only
mounted combat. Range, faction, sight, muzzle obstruction and yaw/pitch gates
protect the flanking route. Death or disabling the operator releases capture.

Infantry accelerate/decelerate, layer distance-driven legs beneath upper-body
clips, crouch at existing cover positions, and adapt feet to sampled ground.
Continuous collision-matched berms, near/distant forest and an extraction gate
conceal the perimeter. Escapes return to the last safe checkpoint; falling actors
cannot overwrite it. Your footstep playback adjustment to **−26 dB** is preserved.
High was selected for the new rendered validation and screenshots without changing
the game's default Auto preset or your saved settings. See
[handling/nest/perimeter validation](docs/HANDLING_NESTS_VALIDATION.md).

The combat-feedback pass adds actor-validated dialogue and firing, layered bounded
explosions, shared muzzle effects, distance-driven infantry legs, hit reactions and
a downed first-person death camera. Wind uses seamless overlap-added loops with
staggered canopy/gust layers. The radio desk has nonverbal positional static, hum
and intermittent signal tones. F10 now has independent **Ambience**,
**Communications** and **Artillery** volume sliders. Artillery is on for new settings;
previously saved choices are preserved. No voice pack or spoken recordings were added.
See [combat-feedback validation](docs/COMBAT_FEEDBACK_VALIDATION.md).

The latest targeted pass fixes ghost gunfire, adds conservative Auto/Low/Medium/High
graphics and revises foliage, terrain, fortifications, equipment and character heads.
See [polish validation and screenshots](docs/POLISH_VALIDATION.md) for exact changes,
performance, tests and remaining art limitations. This remains an interim visual build.

Both factions now use skinned character scenes sharing 17 named bones, nine
AnimationPlayer clips, an AnimationTree state-machine hook and a right-hand weapon
socket. A CC0 soldier body by nisu is retargeted into this rig; faction helmets,
webbing, gaiters, colors and equipment remain separate. These are low-detail
development models, not final photorealistic characters. Every carried weapon has
first-person sleeves, hands and a resource-defined support-hand position.

English and German voice sets each provide eight combat categories and a radio
briefing. Spotting, damage, reload, advance, lost sight, nearby explosives, casualty
and death feed a scene-owned dialogue scheduler. Actor cooldown is 5 seconds,
actor/category cooldown 16 seconds, shared/category cooldown 10 seconds, and the
global channel reserves the line duration plus 0.4 seconds. Casualty calls can wait
up to 8 seconds while the speaker remains alive and enabled. Actual death cancels
pending lines and clears the active subtitle; it never starts a new spoken/subtitle
event. Text keys, fallback subtitles, timings and recordings are separate.
**Recording slots are empty: dialogue is subtitled but silent.** No fake speech is
generated. Missing recordings are labeled in subtitles/settings. F10 can enable
explicit NON-SPEECH diagnostic tones to test the spatial Dialogue/DialogueInterior
pipeline. Production filenames and delivery requirements are in the
[recording manifest](docs/VOICE_RECORDING_MANIFEST.md).

An authored overcast sky, denser tree crowns, deterministic placement variation,
near/far tree meshes (34 m transition, 85 m cull), moss variation and shallow
collision-matched forest relief improve the exterior. Road/range/bunker/flank track
heights are preserved. Current navigation has 4,354 open / 4,321 restricted polygons. Impact debris,
bounded decals, smoke, explosion dust and subtle directional near-miss feedback
supplement existing flash/recoil. Reduced-motion settings disable suppression roll.

F10 opens a paused options panel in the menu or mission: FOV 60–110, mouse
sensitivity, master/effects/dialogue volume, subtitles, reduced motion, optional
distant artillery, voice diagnostics and Auto/Low/Medium/High graphics presets.
Auto starts conservatively on integrated or unknown hardware. Options persist in
`user://settings.cfg`. Escape still only releases
the mouse. Checkpoints before the bunker and after documents retain position,
health (minimum 50), carried magazines/reserves, selected slot, objective and defeated
enemies across death/Enter. They are session-only; faction changes/new games and
completion/restart clear them. Live enemies and supplies reset on reload.

## Environment and audio foundation

The mission now uses branched conifer and broadleaf meshes, textured trunks/roots,
wind-responsive foliage, ferns, grass, shrubs, leaf litter, scattered rocks, fallen
logs and raised rock banks. The forest floor blends an irregular muddy trail and
wheel ruts. Understory uses small MultiMesh groups with 45 m visibility ranges;
trees render to 85 m with a separate distant mesh tier. Fine foliage does not cast
expensive individual shadows.

The fortifications have individual sandbags, timber revetments, camouflage strips,
barbed wire and contextual German signs. Weathered concrete and lower-wall paint
frame a command post with map/operations, radio, office and storage/records areas.
Details include original maps, paperwork, telephone, radio controls, typewriter,
chairs, drawers, crates, suspended lamps and conduit. New office furniture has
collision and is included in the navigation bake. Most trim uses existing collision.

Weapons have new beveled geometry, barrels, sights, grips, mechanisms and equipment
details. Shared muzzle flashes use a soft additive shader; handling adds recoverable
camera kick, bounded burst climb and weapon inertia. Both factions use the shared rig, modular equipment and
held firearm socket; damage and navigation remain independent of visual geometry.

Forward+ uses ACES, balanced lighting and sky reflections on every preset. High adds
SSAO/SSIL, volumetric haze, 65 m shadows, 2x MSAA and screen-space reflections. Low
uses 80% resolution, shorter shadows, reduced understory, FXAA and no expensive
screen-space effects. The full applied-settings table is in the polish report.

Audio now uses distinct original layered firearm reports, mechanisms/reload cues,
surface-specific impacts/footsteps, explosions, wind, birds, distant combat and
bunker hum. Distant artillery is now an optional quiet off-map channel; ambient
rifle bursts no longer follow the listener. A reverb bus and ambience crossfade distinguish bunker/exterior space.
These are authored synthesis placeholders, not authentic recordings. Speech uses
the separate silent-until-recorded voice sets described above.

See [ASSET_ATTRIBUTION.md](ASSET_ATTRIBUTION.md) for all sources/licenses and the
remaining recording/model requirements. Original asset builders live in `tools/`;
the baked assets are committed and need no generation step to play. Presentation
composition lives in `scripts/presentation/`, separate from combat state.

## Run and controls

Open `project.godot` and press **F5**, or run `godot --path .` from this directory.
The default scene is `res://scenes/ui/title_menu.tscn`: **BASTION FRONT**, a live
bunker backdrop, Allied start, German loadout test, field manual, credits and quit.
Start the mission directly with:

```powershell
godot --path . res://scenes/missions/forest_command_post.tscn
```

The original `scenes/main.tscn` remains the regression sandbox (open it and use F6).
No plugins, dependencies or asset downloads are required.

| Input | Action |
| --- | --- |
| WASD / Mouse | Move / look |
| Hold Shift | Sprint |
| Space | Jump while standing and grounded |
| Hold Ctrl | Crouch; standing requires overhead clearance |
| Left click / hold | Fire; pistols/launchers need separate clicks; automatic guns repeat |
| Hold right click | Aim, narrow FOV and reduce firearm spread; also aim behind mounted MG sights |
| R | Reload carried magazine or mounted belt |
| 1 / 2 / 3 / 4 | Select loadout slot |
| Mouse wheel | Cycle carried weapons |
| G | Throw faction grenade |
| E | Use aimed-at object within 2.8 m; mount/dismount gun |
| F1 / F2 | Restart as Allied / German while in staging |
| F3 | Generate/load a new operation while staging remains unlocked |
| F10 | Open/close paused settings; saves options on close |
| F9 | Toggle operation seed/zone choices and audio/soldier audit: names through cover, positions, states, recent shot sources and audio buses |
| Enter | Resume latest checkpoint after death; fresh restart after completion |
| Esc | Release mouse; click recaptures without firing |
| Alt+F4 / window close | Quit |

Focus loss also releases the mouse. Released mouse disables movement input but
**does not pause combat**. Mount while standing and not reloading. Mounted aiming
is limited to 55 degrees yaw and 25 degrees pitch either side. Switching and
grenades are disabled while mounted.

Footsteps use softened boot/scuff sounds, with playback 12 dB quieter than the
previous mix and a 12 m audible range. On either MG emplacement, hold right mouse
to bring the camera behind the sights and zoom; release it for the normal view.
Dismounting restores the camera and clears aim input, including on player death.

## Loadouts, ammunition and supplies

| Faction | Slot 1 | Slot 2 | Slot 3 | Slot 4 | G |
| --- | --- | --- | --- | --- | --- |
| Allied | M1911 | Thompson | Bazooka | unused | Mk2 fragmentation grenade |
| German | Walther P38 | MP40 | StG 44 | Panzerfaust | Stick grenade |

| Weapon | Magazine / initial reserve | Reload seconds |
| --- | --- | --- |
| M1911 | 7 / 105 shared .45 ACP | 1.8 |
| Thompson | 30 / 105 shared .45 ACP | 2.2 |
| P38 | 8 / 128 shared 9 mm | 1.8 |
| MP40 | 32 / 128 shared 9 mm | 2.4 |
| StG 44 | 30 / 120 | 2.6 |
| Bazooka | 1 / 4 | 3.0 |
| Panzerfaust | 1 / 3 | 4.0 |
| Fixed M1919 .30 cal | 100 / 500 | 4.0 |
| Fixed MG42 | 200 / 600 | 5.0 |

Shared reserves initialize once per ammo type using the largest configured reserve
in the loadout. Magazines remain individual across switching. The original sandbox
still starts the standalone M1911 at 7 / 35. Reload transfers only missing rounds
at completion, retaining partial-magazine ammunition. Firing/switching cannot
bypass reload. Empty handheld weapons need R; emplacements also reload when fired
empty. Mounted reserves are separate and finite. These are prototype tuning values.

Both grenades start at three, bounce and detonate after three seconds; throwing has
a 0.8-second cooldown and is blocked during reload. Launchers fire physical
projectiles with gravity and contact detonation. Explosions use distance falloff,
solid-cover occlusion and self-damage. Firearms retain camera and barrel-obstruction
hitscan checks. Player and infantry have 100 HP with uniform body damage.

Walk over labeled supplies: health restores up to 40 HP, ammunition adds 40 per
carried firearm ammo type and two launcher rounds, grenades add three (cap eight).
Ammo caps are resource-derived. Unneeded supplies remain; collected crates respawn
after 25 seconds. Range targets reset three seconds after destruction.

## First mission flow

1. Start in the conifer forest beside a dirt trail. The range on the left
   has two targets, an M1919 and an MG42. Supplies and faction stations are beside/
   behind spawn. F1/F2 or E at stations restart with the chosen faction.
2. Follow the trail through two patrol encounters. Solid trunks and road obstacles
   block sight and provide space to flank.
3. Approach the fortified position and trench lane. A faction-correct defensive MG covers
   the central approach. Clear or flank it, then capture it with E. The east supply
   track around x=12 provides ammo/health and an approach outside the central gun arc.
4. Enter the bunker through the central gap. Connected radio, operations and storage
   rooms contain guards and additional supplies. A checkpoint activates on the
   approach immediately before the entrance.
5. Press E at the operations documents in the left rear room, then reach the marked
   rear exit. Extraction is locked until documents are taken. Completion stops
   combat and offers Enter-to-restart. Taking documents records the second checkpoint.

Seven infantry actors include the gunner. Allied play uses German opponents;
German testing assigns Allied relationships, visuals, voice set and weapons to the same
actors. This is one test mission, not two authored campaigns. The defensive gun
is an MG42 against Allied players and an M1919 against German players.

## Enemy behavior

The reusable actor retains idle, patrol, alert, chase, attack, hurt and death.
NavigationAgent3D follows baked paths. Vision retains 24 m range, a 100-degree cone
and head-directed occlusion. Hidden movement does not refresh sight memory; four
seconds without renewed information ends direct pursuit. Mission infantry then
search around the remembered point for at most five seconds before returning idle.

Mission infantry vary speed, reaction delay and weapons. German opponents cycle
P38, MP40 and StG 44; Allied variants use M1911 and Thompson. They stop within 12 m,
fire 2-4-round bursts with 0.7-1.3-second rests and reload. Mission damage is reduced
to eight per hit. The gunner uses 24 m and four-round bursts with one-second rests.
Attacks require current sight. Hurt interrupts attacks for 0.3 seconds and flinches
the mesh; death disables combat and collision.

Hostile gunshots within 28 m and explosions/mounted fire within 45 m can alert
enemies. Hearing records an approximate sound position, never a live hidden-player
position. It is radius-based, passes through walls and cannot authorize firing
without vision. The original sandbox retains its previous AI timing.

The optional `InfantryTactics` component shares observed positions with nearby
same-faction actors every 2.5 seconds. Every two seconds it evaluates six authored
cover points, requiring actual low-height occlusion and unoccupied space. Odd-role
actors can make short lateral advances while an ally visibly engages; other actors
hold sight-gated bursts. Search picks bounded offsets from the last report. Motor
repaths remain throttled to 0.25 seconds. Muzzle obstruction/friendly checks prevent
shooting into allies. This is small encounter coordination, not a full squad planner.

## Architecture and asset hooks

- `resources/factions/{allied,german}.tres` / `FactionData`: loadouts, grenade,
  mounted scene, hostility, language, uniform/optional variants, sleeve color and voice references.
- `resources/weapons/*.tres` / `WeaponData`: identity, damage, fire mode/rate, ammo,
  reload, recoil/spread, projectile settings and presentation references.
  `WeaponBase` owns instance timers/magazines; `WeaponInventory` and `AmmoPool`
  handle selection/shared reserves. No behavior script per weapon or nationality.
- `HitscanShot`, `ProjectileLauncher`, `ExplosiveProjectile`, `MountedWeapon`:
  reusable delivery mechanisms. `HealthComponent` / `DamageReceiver` handle health
  and faction filtering. Player input stays in `player_weapon.gd`; existing
  movement and mouse-look scripts are unchanged.
- `scripts/gameplay/{player_interaction,supply_pickup,footsteps}.gd`: composed
  interaction, supplies and movement sound. `InteractionPoint` provides stations.
- `scripts/systems/combat_audio.gd`: bounded spatial playback, pitch variation and
  separate AI noise events. `resources/audio/prototype_palette.tres` accepts
  gunshot, reload, dry-fire, impact, explosion, footstep and mounted streams. Empty
  slots synthesize short original sounds. Weapon resources override shot/reload/dry.
- `assets/weapons/{allied,german}/*_viewmodel.tscn`: replaceable primitive models
  sharing flash/light, visual recoil and aim/reload poses. Retain the WeaponViewModel
  interface and Muzzle/Flash/Light nodes when replacing art. Add final hand/weapon
  animation inside these visual scenes. `support_hand_position` tunes shared hands.
  `world_model_scene` remains a reserved
  resource hook, not an equipped-world-model pipeline.
- Retained final asset directories: `assets/characters/{allied,german}`,
  `assets/environments/`, `assets/props`, `assets/textures`, and
  `assets/audio/{weapons,ambience,voice_allied,voice_german}`.
- `scenes/missions/forest_command_post.tscn`: mission composition and encounters.
  `command_post_environment.tscn`: editable static forest/fortification/interior.
  `resources/missions/forest_command_post.tres` / `MissionData`: mission text;
  `combat_mission.gd`: coordinator. `PrototypeSession` retains faction/checkpoint.
- `scripts/presentation/{character_animation,viewmodel_arms,dialogue_director,
  infantry_voice,combat_effects,suppression_feedback}.gd`: presentation components.
  Replace `FactionData.uniform_scene` with a compatible imported GLB; preserve
  `Skeleton3D/WeaponSocket`, `AnimationPlayer` clip names and `AnimationTree` hook.
  Replace audio by assigning streams in `resources/characters/*_voice.tres`.
- `tools/build_characters.gd` and `tools/retarget_soldier.gd` author the rigged
  faction scenes. `tools/configure_fidelity.gd` authors voice defaults/hand poses;
  rerunning it intentionally restores defaults, so preserve custom recordings first.
- `scenes/weapons/*_projectile.tscn`, `scenes/mounted_weapons/*.tscn`,
  `scenes/pickups/*.tscn`: configured reusable instances.
- `resources/missions/command_post_navigation.tres`: committed 5,792-polygon bake.
  Retain `.gd.uid` sidecars; generated caches/captures remain ignored in `.godot/`.

## Validation

Validated with Godot **4.7.2**, including Vulkan Forward+ display runs. Run windowed
suites sequentially, keeping their window focused for injected input checks:

```powershell
godot --headless --path . --editor --import --quit
godot --path . --quit-after 180
godot --path . --script res://tests/movement_smoke.gd
godot --path . --script res://tests/weapon_smoke.gd
godot --headless --path . --script res://tests/infantry_smoke.gd
godot --headless --path . --script res://tests/combat_prototype_smoke.gd
godot --headless --path . --script res://tests/defensive_mg_smoke.gd
godot --path . --script res://tests/mission_flow_smoke.gd
godot --path . --script res://tests/presentation_smoke.gd
godot --headless --path . --script res://tests/fidelity_smoke.gd
godot --path . --script res://tests/polish_smoke.gd
godot --path . --script res://tests/combat_feedback_smoke.gd
godot --path . --script res://tests/cleared_command_post_smoke.gd
godot --path . --script res://tests/combat_feedback_capture.gd
godot --path . --script res://tests/presentation_capture.gd
godot --path . --script res://tests/character_capture.gd
```

Original suites cover movement, collision/crouch, capture, pistol ammo/reloads/
obstruction, infantry navigation/vision/memory/combat/death and restart. New combat
tests cover all carried weapons, explosives, cover/falloff/self-damage, shared
reserves, supplies, mounts, factions, hearing and extraction. The defensive MG
suite verifies live attacks, capture and mounted player death. Mission-flow tests
inject controls and physically walk the route, mount a gun, collect documents,
exit and restart. They remove enemies to isolate route/input; combat is tested
separately. Display runs save screenshots under `.godot/validation/`; selected
presentation captures are retained in `docs/screenshots/`. The presentation test
checks menu-to-mission transition, material/dressing presence, voice slots and audio
assets. The capture script samples frame rate and draw counts from four viewpoints.
Headless Dummy-driver runs emit AI hearing events but skip inaudible PCM playback;
native Vulkan runs validate actual audio-node playback and cleanup.

On the development Radeon 860M at 1280x720 with VSync, the original four sampled
views measured 60 FPS. After the pass, the forest measured approximately 52-59 FPS
and the bunker/radio/operations views approximately 60 FPS. These are warm static
viewpoint samples, not minimum combat frame rates or a cross-hardware guarantee.
The preceding pass submitted about 1.93 million forest primitives across rendering
passes. The current iteration's samples are recorded in `docs/FIDELITY_VALIDATION.md`.
The fidelity suite adds actual animation/skin checks, voice cooldowns, cover/search,
flank connectivity, options integration and death/Enter checkpoint restoration.

Retained screenshots: [title](docs/screenshots/title_menu.png),
[forest](docs/screenshots/forest.png), [bunker](docs/screenshots/bunker.png),
[operations room](docs/screenshots/operations.png), [combat](docs/screenshots/combat.png),
[faction characters](docs/screenshots/characters.png).

After static collision edits, rebuild navigation:

```powershell
godot --headless --path . --script res://tests/bake_navigation.gd -- --mission
# Original sandbox:
godot --headless --path . --script res://tests/bake_navigation.gd
```

Bakes use world collision, 0.4 m clearance, 1.8 m height, 0.2 m climb and 35-degree
slopes. Solid trunks are included; visual canopies and actors are excluded.
For shells unable to write the normal Godot cache, use process-local paths:

```powershell
$env:APPDATA = Join-Path $PWD '.godot\validation\roaming'
$env:LOCALAPPDATA = Join-Path $PWD '.godot\validation\local'
New-Item -ItemType Directory -Force $env:APPDATA, $env:LOCALAPPDATA | Out-Null
```

The restricted validation environment emits `Failed to read the root certificate
store` at startup. This existing OS diagnostic does not prevent local importing,
rendering, physics or gameplay.

## Limitations and next phase

- This is an interim art pass, not finished photorealism. Characters use a low-poly
  donor body, approximate faction equipment and short authored animation clips.
  Faces, finger contact, uniform tailoring and skinning at extreme poses still need
  production art/animation. First-person hands use posed geometry and procedural
  magazine/handle choreography, without finger IK or production reload clips.
  German mode remains a loadout test. Distance-driven legs and two ground samples
  improve foot placement; planted-foot locking, lateral slope roll and authored
  production locomotion remain future work. Smoke/fire are original shader particles;
  debris is visual-only and the pressure skirt substitutes for screen distortion.
- No shell ejection, ragdolls or body-part damage. Decals expire after 12 seconds
  and are capped at 40; impact bursts at 24 and smoke puffs at 12. Viewmodels can
  visually clip walls; obstruction still blocks damage. Panzerfaust reload represents
  readying the next disposable unit.
- Radial grenade damage, no fragment simulation/cooking, armor/vehicle simulation,
  penetration or NPC explosives. Mounted ammo and enemy ammunition are finite.
- Authored synthetic effects await licensed recordings and a human audio-mix pass.
  There is source-position reverb and ambience blending, but no acoustic occlusion.
  Dialogue/briefings are labeled as missing pending licensed English/German recordings;
  opt-in diagnostic tones are non-speech pipeline tests only.
  No dynamic navigation rebakes, elaborate cover peeking or moving-obstacle avoidance.
- Tree tiers can visibly transition; no baked impostors. Ground relief is shallow;
  final sculpted terrain and natural leaf/needle textures remain needed. Checkpoints
  do not survive application exit. No campaign progression or gamepad support.
  Automated tests do not replace human difficulty/feel/audio tuning.

Next phase: **visual fidelity, licensed sound assets, animation and level polish**.
Prioritize terrain/foliage, readable fortifications, cinematic lighting, rigged
faction equipment/hands, spatial ambience, weapon mixes and encounter pacing.
