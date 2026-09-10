# Changelog

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
