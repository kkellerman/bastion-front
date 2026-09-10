# Bastion Front

Milestone 2: a first-person pistol and movement sandbox for Godot **4.7.x**, using typed
GDScript, Forward+ and Vulkan. `wolf_like_godot_starter.md` remains the authoritative
design specification. The primitive forest is a blockout for the future German
forest approach, not the final visual target.

## Run

Open `project.godot` in Godot 4.7.x and press **F6** with `scenes/main.tscn` open,
or press **F5** from any scene. No editor configuration or plugins are required.
From this directory:

```powershell
godot --path .
```

The configured main scene is `res://scenes/main.tscn`. It composes the reusable
player and the outdoor sandbox; neither component depends on a mission manager.

## Controls

| Input | Action |
| --- | --- |
| W / A / S / D | Forward / left / backward / right (physical key positions) |
| Mouse | Look; pitch limited to 85 degrees up/down |
| Hold Shift | Sprint |
| Space | Jump when grounded and standing |
| Hold Ctrl | Crouch; release to stand when there is room |
| Esc | Release mouse and disable movement input |
| Left click | Fire one shot, or recapture the released mouse without firing |
| Hold right click | Aim with centered sights, narrower FOV and reduced spread |
| R | Reload |

Losing application focus also releases the mouse. Gravity continues while the
mouse is released. Click inside the game to resume. Use the window close button
or Alt+F4 to quit. There is no pause menu.

## Pistol and target

The first Allied pistol is an **M1911 placeholder**. It starts with **7 rounds in
the magazine and 35 in reserve**. Each click fires one shot; holding the trigger
does not repeat. The rate limit is 300 rounds/minute (at least 0.2 seconds between
shots). Empty fire does not consume reserve or automatically reload.

Press **R** to reload in **1.8 seconds**. Firing is blocked during reload. Only the
missing rounds transfer from reserve when the timer completes, so partial reloads
retain ammunition. With insufficient reserve, the magazine fills only as far as
available rounds allow. A full magazine or empty reserve prevents reloading.
Reloading continues while the mouse is released. There is no chamber/+1 model.

The board straight ahead of spawn has **100 health** and displays its remaining
health. Each hit deals **25 damage**: four hits destroy it. It automatically resets
after **3 seconds**. Shots stop at solid cover, including obstructions between the
camera and offset barrel, and have an 80 m maximum range. The HUD shows magazine /
reserve and reload/empty status. Restart the game to replenish the finite ammo.
These are prototype tuning values, not researched weapon-performance claims.

## Weapon architecture

- `scripts/weapons/weapon_data.gd` and `resources/weapons/m1911.tres`: shared
  configuration for identity, faction metadata, damage, rate, trigger mode, ammo,
  reload, recoil, spread, range and presentation references. Runtime state never
  mutates the Resource. Projectile/world-model/audio fields are reserved and unset.
- `scripts/weapons/weapon_base.gd`: per-instance magazine, reserve, cooldown and
  reload state. Emits signals and does not depend on player input or faction.
- `scripts/weapons/hitscan_shot.gd`: camera aim plus barrel obstruction raycasts;
  delegates damage to a `DamageReceiver` and emits impacts.
- `scripts/components/{health_component,damage_receiver}.gd`: reusable damage
  components. The receiver references health explicitly; no target-name checks.
- `scripts/weapons/player_weapon.gd` and `scenes/weapons/player_weapon.tscn`: compose
  input, weapon state, shot behavior, viewmodel and HUD. The rig is attached under
  the player camera in `scenes/player/player.tscn`. Movement scripts are unchanged.
- `scripts/weapons/weapon_viewmodel.gd` and
  `assets/weapons/allied/m1911_viewmodel.tscn`: primitive first-person pistol,
  muzzle marker/flash/light, visual recoil, aim/reload poses and optional audio.
- `scripts/weapons/weapon_hud.gd` and `scenes/ui/weapon_hud.tscn`: crosshair, control
  hint and signal-driven ammo/reload display.
- `scripts/gameplay/test_target.gd` and `scenes/interactables/test_target.tscn`:
  health readout and timed target reset, instanced in `scenes/main.tscn`.
- `tests/weapon_smoke.gd`: ammo, reload, damage, obstruction, input and rendering
  regression checks. New scripts have Godot-generated `.gd.uid` sidecars.

To add another hitscan weapon later, create another `WeaponData` resource and a
compatible `WeaponViewModel` scene, then assign the data on the rig's `WeaponBase`.
The generic input component also supports a data-selected automatic trigger.
Only the M1911 is supplied; there is no inventory or weapon switching yet.
Projectile launchers must receive a separate projectile shot component in their
milestone; the current rig explicitly rejects projectile configuration instead of
silently firing a hitscan approximation. No faction gameplay has been introduced.

## Scene and file inventory

- `project.godot`: title, main scene, input mappings, physics layers, gravity,
  resolution and renderer configuration.
- `scenes/main.tscn`: launch scene; instances `ForestSandbox`, `Player` and `TestTarget`.
- `scenes/player/player.tscn`: `CharacterBody3D`, capsule collider, head/camera,
  2.5 m interaction ray, standing-clearance shape cast, mouse-look component and weapon rig.
- `scenes/missions/forest_sandbox.tscn`: ground, dirt track, solid perimeter,
  two jump blocks, 15-degree ramp and landing, low crouch passage, trees, sky,
  sunlight and fog. All environment geometry is editable in Godot; no runtime
  generation script is required.
- `scripts/gameplay/first_person_player.gd`: movement, sprint, crouch, jumping,
  gravity, ground handling and overhead clearance.
- `scripts/components/mouse_look.gd`: yaw/pitch and mouse capture/focus handling.
- `assets/environments/germany/placeholder_conifer.tscn`: reusable primitive
  conifer with solid trunk and visual-only canopy.
- `assets/materials/{bark,forest_floor,mud,needles,stone,timber}.tres`: six shared,
  rough, muted placeholder materials.
- `tests/movement_smoke.gd`: executable scene, input and physics checks.
- Script `.gd.uid` sidecars: Godot-generated stable resource identifiers; retain
  these in version control.
- `README.md` and `CHANGELOG.md`: usage, scope, validation and milestone notes.

Empty `.gitkeep` files preserve the specification's future directory layout:
`assets/characters/{allied,german}`,
`assets/environments/{france,low_countries,military,generic_europe}`,
`assets/{props,textures}`, `assets/weapons/{allied,german}`,
`assets/audio/{weapons,ambience,voice_allied,voice_german}`,
`scenes/{characters,weapons,mounted_weapons,pickups,interactables,ui}`,
`scripts/{ai,weapons,factions,systems}`,
`resources/{factions,weapons,characters,missions,items}`, `shaders`, and
`localization`. Reserved folders retain their placeholders; weapon and damage
folders now contain only the Milestone 2 files described above.

The existing specification and `.gitignore` were not modified. Generated imports,
caches, logs and validation captures live under the already ignored `.godot/`.

## Validation

```powershell
godot --headless --path . --editor --import --quit
godot --headless --path . --quit-after 120
godot --path . --script res://tests/movement_smoke.gd
godot --headless --path . --script res://tests/weapon_smoke.gd
godot --path . --script res://tests/weapon_smoke.gd
```

The full smoke test requires a display because headless Godot cannot capture the
mouse. Keep its window focused while it runs. It exercises spawning, input-map
presence, walking, normalized diagonal movement, sprinting, grounded jumping,
airborne jump rejection, landing, crouch clearance, slope ascent/descent, boundary
collision, the interaction ray, look limits, mouse release/recapture and focus
loss. It prints a failure count and saves a rendered frame to
`.godot/validation/sandbox.png`. A headless test run checks spawning and input maps
and explicitly skips display-dependent checks.

The weapon suite checks rate limiting, independent ammo state, empty firing,
partial and insufficient-reserve reloads, repeat-reload rejection, reload timing,
hitscan damage/range, target destruction/reset and camera/barrel cover blocking.
With a display it also injects actual mouse/key events to check recapture without
firing, semi-automatic hold behavior, aiming and R reload. It saves
`weapon_aim.png` and `weapon_sandbox.png` in `.godot/validation/`. Run windowed
suites one at a time, keeping the test window focused.

For a restricted shell that cannot write the normal Godot user cache, set these
process-local paths before running the commands:

```powershell
$env:APPDATA = Join-Path $PWD '.godot\validation\roaming'
$env:LOCALAPPDATA = Join-Path $PWD '.godot\validation\local'
New-Item -ItemType Directory -Force $env:APPDATA, $env:LOCALAPPDATA | Out-Null
```

Development validation used Godot 4.7.2 and a Vulkan Forward+ window on an AMD
Radeon 860M. The restricted environment emits `Failed to read the root certificate
store` at engine startup; this OS certificate access error does not originate in
the game and did not prevent local importing, rendering or physics tests.

## Limitations and next milestone

- Placeholder flat terrain, primitive trees and test fixtures only. Dense foliage,
  realistic assets, terrain detailing and final cinematic lighting remain future
  art work. No third-party assets or dependencies are included.
- No automatic stair stepping, crouch transition animation, footsteps or gamepad
  support. Walkable slopes use native floor snapping; jump onto vertical ledges.
- The interaction ray is only the specification's Milestone 1 scaffold; there are
  no interactables or interaction bindings yet.
- Automated checks do not replace a human movement-feel and mouse-sensitivity
  pass. Tune the exposed movement values in the Player scene as needed.
- This pass follows the requested first-pistol scope within Milestone 2. The spec's
  broader SMG prototype remains deferred. No AI, factions, campaigns or objectives.
- Weapon art, sights, muzzle flash, reload motion and impacts are placeholders.
  Recoil is visual viewmodel kick; there is no camera kick or ballistic recoil model.
  Aiming uses simplified sights and reduced spread; there are no hand animations,
  shell ejection, persistent bullet decals or weapon sounds yet.
- The first-person mesh uses the normal world camera and may visually clip very
  close to walls; obstruction tests still block damage through cover.
- No ammo pickups, switching, inventory, projectiles or explosives. Later weapon
  types can reuse data and ammo state but need their milestone-specific components.
