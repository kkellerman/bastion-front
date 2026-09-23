# Character, weapon grip and ragdoll pass

Validated September 23, 2026 with Godot 4.7.2, Forward+/Vulkan on Radeon 860M.

## Changes

- Replaced dangling donor hands and segmented first-person fingers with shared rounded palm/finger meshes. Trigger fingers and opposing thumbs wrap the grips; support hands cradle fore-ends and close around magazines during first-person reloads.
- Shared wrist anchors align weapon meshes and hands in first and third person. MP40 and launcher support positions follow their different geometry. Infantry arm solving keeps the supporting wrist on the weapon during movement and recoil, and raises the weapon when aiming. Mounted gunners have revised wrist positions/orientations.
- Closed the first-person wrist joins and added missing front/rear sight pedestals on pistols and long guns; the sights no longer float above the receiver/barrel.
- Retargeted upper/forearm geometry now matches the target segment length, as well as its direction. Reduced upper-arm and trouser bulges; revised head/jaw/skull profile, ears, skin color and normal-map encoding.
- Replaced the single shared painted face with three baked low-poly head variants per faction. Each has distinct skull, jaw, nose, eye spacing, complexion, stubble and asymmetry. Separate skinned eyelids, sclera, irises and pupils replace the shader-painted eyes, while all head geometry remains bound to the existing Head bone for animation and ragdolls.
- Added fitted short-hair caps with distinct colors and hairlines, visible only at the temples and nape beneath the original helmet rims. Modeled upper/lower lips and a restrained mouth crease make closed mouths readable without teeth, jaw bones or helmet changes.
- Disabled the unused AnimationTree: it was actively restoring the default pose underneath AnimationPlayer and the ragdoll system. The death clip lowers the hips and bends the knees before the physical handover.
- Settling measures translation and rotation of every physical bone. Settled poses are retained in the skeleton, physical bodies are removed, and all six simulation slots become reusable. The maximum lifetime also applies to bodies that are still falling.
- Rockets align their motor with the launch direction and no longer receive grenade tumble. Explosion knockback uses the blast origin independently of the damage owner. Aiming respects a 60-degree FOV preference. Impact gradient textures and hand meshes are cached.

## Rendered evidence

These are actual engine captures, not generated illustrations.

- [Before](screenshots/character_grips_before.png)
- [After: both factions aiming](screenshots/character_grips_after.png)
- [Side view: weapon and arm alignment](screenshots/character_grips_side.png)
- [First-person magazine grip](screenshots/character_grips_reload.png)
- [Aimed pistol grip](screenshots/character_grips_pistol_aim.png)
- [Settled corpse after physical bodies retire](screenshots/character_ragdoll_settled.png)

## Validation

The new `tests/character_grips_smoke.gd` checks all seven handheld weapons, shared wrist anchors, support contact during idle/aim/walk/fire, completed reloads, rocket thrust and flight at four headings with elevation, low-FOV aiming, six-body budget exhaustion/reuse, lateral movement, forced retirement, pose persistence, blast direction, and an actual infantry death through ground settling. It passes headless and with native rendering. Its `--capture` mode also exercises and captures first-person aiming. `tests/fidelity_smoke.gd` verifies that both factions expose all three deterministic face variants, that each head contains separate skin, hair, lips, sclera, iris and pupil surfaces, and that face variation does not alter helmet dimensions.

Existing weapon, combat prototype, combat feedback, defensive MG, fidelity, handling/nests/perimeter, infantry separation, infantry, locomotion/stance, operation variants, polish and presentation suites pass. Native movement, operation controls, mission flow and cleared-command-post walkthroughs pass. The latter kills all seven enemies and walks through the bunker without subsequent hostile sound, shots or flashes.

Two stale test assumptions were corrected: locomotion now checks the corpse pelvis rather than a scripted root rotation; mission flow reads the configured interaction binding (F) rather than pressing E, which is lean-right.

The footsteps/mounted-aim suite passes its mounted aim/fire/release checks, but retains one unrelated failure: the metal-footstep asset exceeds the opening-attack peak threshold. That asset is byte-identical to HEAD and was not changed. Settings persistence was tested with APPDATA redirected into `.godot/validation/character_audit_userdata` to avoid sandbox restrictions on the normal user directory. Restricted runs also emitted OS certificate-store and, before this redirection, shader-cache/log-write diagnostics.

## Reproduction

Use the console Godot executable on Windows so batch invocations wait for completion and return the test's exit status.

```powershell
godot --headless --path . --script tools/build_characters.gd
godot --headless --path . --script tools/fit_weapon_sights.gd
godot --headless --path . --script tests/character_grips_smoke.gd
godot --path . --script tests/character_grips_smoke.gd -- --capture
godot --path . --script tests/character_capture.gd
```

Captures are written under `.godot/validation`; selected comparisons are retained above.

## Limits

This improves the existing low-poly assets. It is not a replacement with production character scans, facial blend shapes, independently animated fingers, or a full authored reload library. The shared 17-bone rig remains; the eyes do not track targets and the faces do not animate speech. Shoulder, elbow and cloth deformation still have limits at extreme angles. Ragdolls remain world-colliding only and do not collide with each other. No new worst-case combat performance benchmark or foliage overhaul is claimed.
