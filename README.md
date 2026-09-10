# Bastion Front

A playable WWII combat and first-mission presentation slice for **Godot 4.7.x**, typed
GDScript, Forward+ / Vulkan. `wolf_like_godot_starter.md` remains authoritative.
This pass follows the explicitly expanded combat/mission scope; the specification's
milestone numbering is unchanged. The visual pass combines CC0 photographic PBR
materials with original interim environment, equipment and sound assets.

## Visual and audio pass

The mission now uses branched conifer and broadleaf meshes, textured trunks/roots,
wind-responsive foliage, ferns, grass, shrubs, leaf litter, scattered rocks, fallen
logs and raised rock banks. The forest floor blends an irregular muddy trail and
wheel ruts. Understory uses small MultiMesh groups with 45 m visibility ranges;
trees render to 80 m. Fine foliage does not cast expensive individual shadows.

The fortifications have individual sandbags, timber revetments, camouflage strips,
barbed wire and contextual German signs. Weathered concrete and lower-wall paint
frame a command post with map/operations, radio, office and storage/records areas.
Details include original maps, paperwork, telephone, radio controls, typewriter,
chairs, drawers, crates, suspended lamps and conduit. New office furniture has
collision and is included in the navigation bake. Most trim uses existing collision.

Weapons have new beveled geometry, barrels, sights, grips, mechanisms and equipment
details. Shared muzzle flashes use a soft additive shader; recoil includes small
translation/roll feedback. German infantry use a field-uniform mannequin with
helmet, boots, webbing and gear; held models follow the equipped firearm.

Forward+ uses ACES tone mapping, restrained desaturation, SSAO, low-intensity SSIL,
volumetric haze, 65 m directional shadows, 2x MSAA plus FXAA, warm interior lights
and sky-based material reflections. Settings are tuned rather than maximized.

Audio now uses distinct original layered firearm reports, mechanisms/reload cues,
surface-specific impacts/footsteps, explosions, wind, birds, distant combat and
bunker hum. A reverb bus and ambience crossfade distinguish bunker/exterior space.
These are authored synthesis placeholders, not authentic recordings. German text
and future recordings are separate in `resources/characters/german_voice.tres`.
Five categories connect to existing state/reload events; grenade-warning and
casualty categories are prepared hooks. No fake German speech is generated.

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
| Hold right click | Aim, narrow FOV and reduce firearm spread |
| R | Reload carried magazine or mounted belt |
| 1 / 2 / 3 / 4 | Select loadout slot |
| Mouse wheel | Cycle carried weapons |
| G | Throw faction grenade |
| E | Use aimed-at object within 2.8 m; mount/dismount gun |
| F1 / F2 | Restart as Allied / German while in staging |
| Enter | Restart after death or mission completion |
| Esc | Release mouse; click recaptures without firing |
| Alt+F4 / window close | Quit |

Focus loss also releases the mouse. Released mouse disables movement input but
**does not pause combat**. Mount while standing and not reloading. Mounted aiming
is limited to 55 degrees yaw and 25 degrees pitch either side. Switching and
grenades are disabled while mounted.

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
3. Approach the fortified position and trench lane. A gunner-controlled MG42 covers
   the central approach. Clear or flank it, then capture it with E.
4. Enter the bunker through the central gap. Connected radio, operations and storage
   rooms contain guards and additional supplies.
5. Press E at the operations documents in the left rear room, then reach the marked
   rear exit. Extraction is locked until documents are taken. Completion stops
   combat and offers Enter-to-restart; death uses the same restart key.

Seven infantry actors include the gunner. Allied play uses German opponents;
German testing assigns Allied relationships and weapons to the same placeholder
actors. This is one test mission, not two authored campaigns. The defensive MG42
remains a capturable German emplacement in either testing configuration.

## Enemy behavior

The reusable actor retains idle, patrol, alert, chase, attack, hurt and death.
NavigationAgent3D follows baked paths. Vision retains 24 m range, a 100-degree cone
and head-directed occlusion. Hidden movement does not refresh sight memory; four
seconds without renewed information returns enemies to idle/patrol.

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

## Architecture and asset hooks

- `resources/factions/{allied,german}.tres` / `FactionData`: loadouts, grenade,
  hostility, language and future uniform/voice references, independent of meshes.
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
  animation inside these visual scenes. `world_model_scene` remains a reserved
  resource hook, not an equipped-world-model pipeline.
- Retained final asset directories: `assets/characters/{allied,german}`,
  `assets/environments/`, `assets/props`, `assets/textures`, and
  `assets/audio/{weapons,ambience,voice_allied,voice_german}`.
- `scenes/missions/forest_command_post.tscn`: mission composition and encounters.
  `command_post_environment.tscn`: editable static forest/fortification/interior.
  `resources/missions/forest_command_post.tres` / `MissionData`: mission text;
  `combat_mission.gd`: coordinator. `PrototypeSession` retains faction on restart.
- `scenes/weapons/*_projectile.tscn`, `scenes/mounted_weapons/*.tscn`,
  `scenes/pickups/*.tscn`: configured reusable instances.
- `resources/missions/command_post_navigation.tres`: committed 1,236-polygon bake.
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
godot --path . --script res://tests/presentation_capture.gd
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
The final forest view submits about 1.9 million primitives across rendering passes;
the initial unoptimized foliage pass exceeded 14 million and was reduced.

Retained screenshots: [title](docs/screenshots/title_menu.png),
[forest](docs/screenshots/forest.png), [bunker](docs/screenshots/bunker.png),
[operations room](docs/screenshots/operations.png).

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

- The transformation is an interim art pass, not finished photorealism. Procedural
  trees, terrain banks, props, equipment and the unrigged German mannequin need
  professional modeling/animation and production LODs. Allied models remain the
  earlier placeholder. German mode remains a loadout test.
- No hands, skeletal reloads, shell ejection, persistent decals, ragdolls, body-part
  damage or camera recoil. Viewmodels can visually clip walls; obstruction still
  blocks damage. Panzerfaust reload represents readying the next disposable unit.
- Radial grenade damage, no fragment simulation/cooking, armor/vehicle simulation,
  penetration or NPC explosives. Mounted ammo and enemy ammunition are finite.
- Authored synthetic effects await licensed recordings and a human audio-mix pass.
  There is source-position reverb and ambience blending, but no acoustic occlusion.
  No squad/cover tactics, advanced search, dynamic navigation
  rebakes or moving-obstacle avoidance.
- Playable routes retain the original floor heights; apparent terrain relief is
  ground shading, roots, debris and perimeter banks, not sculpted terrain traversal.
  No checkpoints, saving, campaign progression or
  gamepad support. Automated tests do not replace human difficulty/feel/audio tuning.

Next phase: **visual fidelity, licensed sound assets, animation and level polish**.
Prioritize terrain/foliage, readable fortifications, cinematic lighting, rigged
faction equipment/hands, spatial ambience, weapon mixes and encounter pacing.
