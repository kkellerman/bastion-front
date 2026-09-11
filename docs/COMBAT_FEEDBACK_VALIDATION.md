# Combat feedback and cleared command-post audit

## Root causes and changes

Child voice processing survived `set_physics_process(false)` on infantry. The
dialogue scheduler checked its own processing, not the owning actor's health and
physics state. Death itself requested a new line. Both voice and scheduler now
validate the speaker; unavailable speakers lose queued lines and active subtitles.
Direct hitscan/projectile and attack callbacks also reject invalid sources. Actual
death no longer begins dialogue. Already-started audio tails may finish; already
launched explosives retain their existing physical damage behavior.

The old wind faded to silence every 12 seconds. Offline overlap-add now produces
11.5-second continuous loops with matching joins. Three persistent forest players
run at staggered offsets with gradual complementary volume variation. Radio static,
electrical hum and intermittent signal/click effects originate at the radio desk
(6, 1.3, -64), with 17 m rolloff and a dedicated reverb bus. No speech is synthesized.
Independent F10 ambience, communications and artillery gains persist. Off-map
artillery varies position, pitch and 12–24 second intervals; existing tails fade
when crossing the bunker boundary. Death/completion stop environmental sources;
scene unload owns final cleanup.

The native shared muzzle component owns flash planes, light and occasional sparks;
it checks actor validity even if the parent is disabled. Infantry muzzle position
now follows the visible held weapon. Explosions use shader-masked clouds, ignition,
dirt/wood/concrete-colored debris, rising smoke, a pressure dust skirt, light and
temporary scorch projection. Health changes trigger cooldown-limited gear/flesh
audio, NPC puffs and a player edge vignette. No gore or hit markers were added.

SkeletonModifier3D layers distance-driven stride, knee bending, foot lift and chest
aim onto the existing clips. Stopped/blocked actors stop stepping; upper-body reload
and fire no longer suspend the legs. This is procedural interim animation, without
terrain foot IK. Death lowers the head to 0.28 m, hides hands/weapon and disables
input. Reduced motion shortens the lowering and removes roll. Suppression no longer
overwrites the death camera.

## Validation and evidence

Passed on Godot **4.7.2**: editor import; rendered movement, weapon, mission-flow,
presentation, polish/audio and combat-feedback suites; headless infantry,
combat-prototype, defensive-MG and fidelity suites. The rendered runs used Vulkan
Forward+ on the Radeon 860M. `git diff --check` also passed. The existing tests were
retained; live-hearing/dialogue fixtures now explicitly enable their test actor.

`tests/combat_feedback_smoke.gd` exercises real navigation stride, stopped motion,
NPC hit cooldowns, stale direct and delayed attack/dialogue calls, mixed killed and
disabled actors, a 26-second quiet window, strict explosion bounds/cleanup, player
hit cooldown, native wind continuity, positional radio, artillery transitions and
death camera/audio cleanup.

`tests/cleared_command_post_smoke.gd` kills all seven named actors through health,
then drives the actual player controller from staging through the forest entrance,
radio room, operations room, rear corridor, radio again and back outside. It turns
at each stop, monitors hostile shots/noise/subtitles/flashes, then waits an additional
26 seconds. Artillery stays enabled to distinguish environment from hostile events.
This is an automated rendered walkthrough, not a claim of manual listening.

The all-killed walkthrough passed on Godot 4.7.2 / Vulkan / Radeon 860M:
**shots=0, hostile subtitles=0, hostile noise=0, muzzle flashes=0**, including
the return route and the extra 26-second wait. All seven bodies reached DEATH
through HealthComponent; none were hidden or freed to achieve the result.

Rendered captures use real mission actors and projectile behavior with a scripted
camera/setup and elevated player health for repeatability:

- [Stride A](screenshots/feedback_stride_a.png), [stride B](screenshots/feedback_stride_b.png)
- [Combat](screenshots/feedback_combat.png)
- [Grenade](screenshots/feedback_grenade.png), [rocket](screenshots/feedback_rocket.png)
- [Downed player](screenshots/feedback_player_death.png)
- [Cleared radio room](screenshots/cleared_radio_room.png), [operations](screenshots/cleared_operations.png)

## Bounds and remaining limitations

At most six explosion groups, each lasting four seconds; Low uses 12 dust/smoke/
debris particles per layer, Medium/High 22. Impact bursts cap at 24, smoke puffs at
12 and decals at 40. Each muzzle reuses one effect and two spark particles. Hit
feedback has a 0.14-second per-actor cooldown; CombatAudio retains a 24-voice cap.
No dynamic shadow is cast by effect lights or particle clouds. These are explicit
cost bounds, not a guarantee of minimum combat FPS on every GPU.

No external dependency, final voice pack, ragdoll or new gameplay subsystem was
added. Radio signals and combat sounds still need authentic licensed recordings
and a human audio mix. Smoke is sprite-based, debris has no secondary collision,
pressure is represented by dust rather than screen refraction, and scorch normals
on rocket contacts are approximate. Presentation upgrades preserve navigation and
explosive damage semantics. Windows CLI can emit the pre-existing root-certificate
store warning; local rendering/audio are independent of that OS diagnostic.
