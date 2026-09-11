# Weapon handling, operated nests and mission perimeter

Godot 4.7.2, typed GDScript, Forward+ / Vulkan, Windows. The original specification,
README, changelog and attribution were read before changes. Existing audio cleanup,
layered effects, dialogue scheduling and death behavior were retained and retested.

## Implementation

- `WeaponHandlingData` and four shared profiles in `resources/weapons/handling/`
  configure camera impulse, recovery, burst growth/cap, lateral motion, inertia,
  breathing and interim reload part placement. Pistols recover at 13/s; SMGs at
  4/s with accumulating bursts; rifles at 4.5/s; launchers have a larger 1.7-degree
  initial impulse. Aim, crouch and reduced motion attenuate camera kick.
- `WeaponHandling` owns camera pitch/yaw offsets, separate from mouse-controlled
  head rotation and suppression roll. Switching, mounting and death reset offsets.
  `WeaponViewModel` retains the existing firing/effect interface and adds inertia,
  breathing and stance presentation. Both hands inherit the moving weapon frame.
- `weapon_reload_motion.gd` separates existing interim SMG/rifle magazine pieces
  and adds replaceable mechanism hooks. The support hand follows the magazine,
  then the handle. Stages read `WeaponBase.reload_progress`, never a second timer.
  Ammo transfer remains atomic at completion, preserving partial reload/shared pools.
- `FactionData.mounted_scene` selects the actual M1919 or MG42 scene. Mission
  composition keeps the `DefensiveMG` path and original transform. The gunner
  binds once at a deterministic operator point; its brain still senses/reacts but
  skips ordinary navigation/combat while bound. Five short CCD iterations per arm
  align the shared skeleton with gun grip targets. The carried infantry gun is hidden.
- Mounted attack checks actor availability, hostility, 24 m visual range, sight,
  muzzle ray obstruction, yaw ±55° and pitch ±25°. Four-shot bursts pause for one
  second; empty belts reload through the existing WeaponBase. Animation and voice
  reload hooks observe the actual mounted weapon. Dead/disabled operators release
  the station, detach the death callback and stop muzzle effects. Player RMB aiming
  and E capture/dismount remain intact.
- Infantry motors now accelerate and decelerate at 9 m/s². Existing cover orders
  request a shallow crouch; a composed stance component adjusts a private capsule
  and eye height. Distance-driven legs combine with acceleration lean, signed
  forward/back movement and two smoothed ground samples. Upper-body clips remain
  independent. Player and NPC controlled death collapse is preserved.
- `mission_perimeter.gd` adds a continuous collision-matched bank on each side,
  distant ground, batched original tree LOD meshes, near bank plantings, timber
  collection gate/signage and extraction supplies. The existing trigger at z=-85
  completes the mission before the rear terrain barrier. The intended forest,
  eastern supply track and bunker paths remain unchanged.
- Out-of-bounds recovery returns position/velocity to the saved checkpoint or
  staging start without resetting health, ammunition or objectives. Checkpoint
  capture rejects escaped/falling positions before they can replace safe data.

## Audio and effects audit

The prior root cause was child voice processing surviving disabled actor physics.
Speaker availability, queued/active dialogue, direct attacks, hitscan/projectile
launch and muzzle effects already validate actor lifetime. This pass strengthens
effect retirement when parent processing stops and when a mount releases its gunner.
No delayed attack system or new audio singleton was introduced.

The cleared-command-post regression kills all seven actual soldiers, physically
walks into the radio room, operations room, rear corridor and back outside, then
waits another 26 seconds: **shots=0, hostile subtitles=0, noise=0, flashes=0**.
Nonverbal communications ambience remains independent of soldiers.

The native mixer regression verifies persistent wind across loop boundaries, the
offline seamless join, positional communications bus, off-map artillery and
interior/exterior tail fades, death shutdown and scene teardown. Existing audio
tails and already-launched explosives retain their natural lifecycle. Speech
recording dictionaries remain empty. The user's -26 dB softened footstep gain is
preserved; the waveform/range test accepts conservative user gain adjustments.

## Validation

All relevant suites were run through the Godot CLI. Rendered tests used the native
audio driver; new evidence runs explicitly select and assert **High**. Validation
APPDATA/LOCALAPPDATA directories live under `.godot/validation/`, isolating the
player's actual settings. Existing graphics tests intentionally exercise all presets.

**Result: import and all listed suites passed.** The new faction/handling suite
also passes with High rendering and checks empty-belt reload/resumption for both
emplacements. Screenshots were inspected and revised after the findings below.

| Check | Coverage |
| --- | --- |
| Editor import | GDScript/resource/scene import |
| movement_smoke | WASD, sprint, jump, crouch/clearance, slopes, capture/release |
| weapon_smoke | M1911 input, hitscan, ammo, reload, ADS, muzzle obstruction |
| infantry_smoke | Navigation, vision, memory, attack, damage, death/restart |
| combat_prototype_smoke | Both inventories, projectiles, pools, pickups, mounts, mission |
| defensive_mg_smoke | Defensive damage, death release, player capture/death |
| mission_flow_smoke | Physical forest→bunker→documents→extraction/restart |
| presentation_smoke | Title/main scene, campaign starts, visual/audio composition |
| fidelity_smoke | Rig, voice scheduling, tactics, checkpoints, settings, hands |
| polish_smoke | Native mixer samples, diagnostic voice routing, graphics presets |
| footsteps_mounted_aim_smoke | Soft steps, local gain/range, ADS at all three mounts |
| combat_feedback_smoke | Ghost events, effect bounds, hits, ambience lifecycle, death |
| cleared_command_post_smoke | All-dead physical walkthrough and hostile-event counters |
| infantry_separation_smoke | Converging live capsules and dead collision release |
| handling_nests_perimeter_smoke | Both faction nests, belts, arcs/LOS, capture, handling/reloads, perimeter/recovery |
| locomotion_stance_smoke | Actual walk/idle, crouch, independent capsule, slope samples, collapse |

New tests exposed and helped fix: faction property deserialization order; duplicate
gunner death callbacks on rebinding; unsafe falling checkpoints; and a screenshot
review caught reversed terrain face winding. Reload framing was raised after
review so the mechanism and hand movement remain visible.

The environment still emits its pre-existing root-certificate-store warning.
It does not affect local import, Vulkan rendering, audio mixing or physics.

## Rendered evidence

These are scripted captures of the actual mission, with temporary test health and
observer positions. They are not claims of a manual listening session or a final
art-quality benchmark.

- [German MG42 operator](screenshots/nest_mg42.png)
- [Allied M1919 operator](screenshots/nest_m1919.png)
- [Reload mechanism/hand movement](screenshots/reload_thompson.png)
- [Active combat](screenshots/feedback_combat.png)
- [Grenade effect](screenshots/feedback_grenade.png)
- [Rocket effect](screenshots/feedback_rocket.png)
- [Infantry stride A](screenshots/feedback_stride_a.png) / [B](screenshots/feedback_stride_b.png)
- [Player death](screenshots/feedback_player_death.png)
- [Radio room](screenshots/radio_room_high.png)
- [Extraction gate](screenshots/extraction_boundary.png)
- [Eastern perimeter](screenshots/east_perimeter.png) / [start boundary](screenshots/start_perimeter.png)

## Performance and remaining production work

The backdrop uses two shadow-disabled MultiMeshes and one static collision berm;
placement is deterministic and bounded (at most 532 trees, shared LOD meshes).
Seven actors add at most 14 terrain rays per physics tick; only the bound gunner
performs arm solving. Existing effects retain six simultaneous explosions,
24 impact bursts, 12 smoke puffs and 40 short-lived decals. No FPS guarantee is
made; High adds the existing expensive fog, shadows and screen-space effects.

This remains interim art. Berms need sculpting and varied ground cover; extraction
is a collection gate/trigger, not a vehicle or cinematic. Foot adaptation is not
full planted-foot IK and does not solve lateral ankle roll or arbitrary stairs.
Hands use rigid authored geometry; magazine/handle hooks approximate mechanisms,
and launcher reloads are placeholders (Panzerfaust means replacing a disposable
unit). No finger solver, shell ejection or ragdoll was added. Mounted mounts retain
simple pedestal geometry. Gun reports, ambience and explosions still use original
synthesis, and authentic licensed English/German speech is still needed.

Next phase: production weapon/hand and infantry animations, accurate faction
models, licensed recordings and human mix review, sculpted terrain/foliage,
fortification detail, lighting and route polish. Keep the established systems.
