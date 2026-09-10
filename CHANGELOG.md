# Changelog

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
