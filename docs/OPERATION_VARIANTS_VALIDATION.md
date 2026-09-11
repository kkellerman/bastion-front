# Constrained operations and forest presentation

Godot **4.7.2**, typed GDScript, Forward+ / Vulkan, Windows, AMD Radeon 860M
integrated graphics. No external assets or dependencies were added. Existing
uncommitted handling, infantry, audio and mounted-weapon work was preserved.

## Playing and reproducing an operation

Run `godot --path .` from the project directory. The title menu has a numeric
Operation Seed field and New Operation button; then choose Allied or German.
F3 generates and loads a new seed only while staging is unlocked. Gunfire,
grenades or leaving z=10 lock it for that scene; returning to staging does not
unlock it. Regeneration is also unavailable while mounted, dead or complete.
F9 toggles the persistent operation seed/option signature and soldier/audio audit.
F10 graphics/audio settings and all existing controls remain in place.

```powershell
godot --path . res://scenes/missions/forest_command_post.tscn -- --operation-seed=1
```

The default seed 1944 selects each zone's baseline option, retaining the original
enemy/patrol/supply positions. Seed 1 selects a restricted eastern track. Seed 73
selects an open track with different forward supplies and fortification dressing.
The seed survives death/Enter and faction switching. New Operation clears the
session checkpoint; checkpoints record and verify the operation seed on restore.
It is an in-session system, not a disk save or campaign progression feature.

## Authored variation and safety

`MissionVariantCatalog` selects `MissionZoneOption` resources using separate local
generators keyed by seed, zone ID and catalog revision. Revision 1 contains seven
`MissionZoneData` resources, sixteen options and 288 possible option combinations.
Small visual placement/orientation differences add variety within bounded anchors.
Seed identity is reproducible within this catalog/engine version; future authored
catalog revisions can intentionally change layouts.

| Zone | Options | Permitted variation |
| --- | ---: | --- |
| Staging | 2 | Safe peripheral ground-dressing kits |
| Forest approach | 3 | ForestPatrol start/route; foliage, debris and tree visual variation |
| Patrol encounters | 3 | RoadGuard route, forward supply positions, open/restricted eastern track |
| Fortification | 2 | PerimeterGuard position, log/crate cover skins sharing fixed collision |
| Bunker | 2 | RadioGuard position, health supply, wall-recess dressing |
| Documents | 2 | Wall-recess crate stacks; interaction and doors stay fixed |
| Extraction | 2 | Peripheral debris/crates; rendezvous gate and trigger stay fixed |

Gameplay tree transforms/colliders, terrain heights, bunker layout, objectives,
required routes and gun nests remain authored. Visual crown selection/orientation
varies around the fixed trunks. Clutter is excluded from the central route, range,
eastern track and bunker circulation. Large new cover props use fixed collision
envelopes for both art kits. Small leaves/twigs/ferns remain visual dressing.

The only optional navigation obstruction is the log stack at (13.1, 0.625, -29).
It narrows one side of the eastern track; the remaining lane is traversable.
Two committed navigation resources match its presence/absence: **4,354 polygons
open / 4,321 restricted**. No runtime baking or arbitrary terrain generation occurs.
Bake bounds cover only the playable rectangle, not exterior scenery banks. Mission
voxels are 25 cm, clearance radius 50 cm, height 1.8 m, climb 20 cm and slope 35°.
The sandbox retains its existing 20 cm bake. Default map rasterization settings
accept both; warning suppression and increased search limits were not used.

Validation exposed two existing trench-cover markers inside solid geometry; they
now sit at (-5.4, 0, -46) and (2.6, 0, -48), beside the respective revetments.
A first dense bake exhausted Godot's 4,096-polygon search budget on long queries.
Coarser mission voxels fixed that underlying cause; regression coverage now checks
both short segments and direct start-to-documents/extraction paths.

## Presentation and scaling

`ForestAtmosphere` and `resources/environments/cold_overcast.tres` define one fixed
weather setup, shared by menu and mission. The layered cloud shader takes its sun
direction from the actual directional light. Exposure, ambient fill, haze color
and distance fog remain coherent across seeds. High adds the existing volumetric
fog/SSAO/SSIL/reflection tiers; Auto/Low retains the same sky and conventional haze.
No weather randomization, weather menu or time-of-day simulation was introduced.
Final rendered review exposed cloud-cell seams from the trigonometric noise hash.
Disabling volumetric fog and the half-resolution pass did not remove them; replacing
the hash with bounded fractional arithmetic did. The unused half-resolution pass
was also removed. The corrected shader retains both cloud layers and fixed lighting.

The ground shader blends offset/scaled samples of the existing CC0 material with
irregular moss, damp ruts, gravel and fine normals. Concrete and bark add native
detail normals; broad patina varies timber/metal. The three original tree meshes
have fuller drooping crowns, rooted trunks and tapered needle cards. Near/far LODs
share their branch skeleton, reducing changes in silhouette at the transition.

The perimeter is a closed multi-ring terrain surface with matching collision,
irregular rock groups, planted slopes and forest behind the crest. A curved trail
is shaded into the rear bank beyond the existing extraction gate. Near/far foliage
uses local deterministic placement and excludes the trail. Horizon trees occupy
20 m spatial MultiMesh groups rather than two map-wide batches. Low uses 75% of
each horizon group and a 105 m cull; Medium/High use full groups up to 140 m.
Existing ground-vegetation density, near/far tree limits and shadow tiers remain.

## Validation

**Result:** all fifteen retained smoke suites and both new operation suites passed.
The additional seed-1 restricted-flank input walkthrough passed. Final editor import
and native menu launch completed without parser, scene/resource or navigation errors.

- `operation_variants_smoke.gd`: 28 runs across both factions and seeds 1944,
  0–9, 73 and 90210, repeating 1944. All sixteen authored options are exercised.
  Checks grounded spawn, deterministic dressing, enemy/supply clearance, patrols,
  cover markers, capsule sweeps on main/flank/full mission routes, correct prebake,
  faction nest/operator binding, document interaction ray, checkpoint seed isolation,
  regeneration lock and physical extraction overlap.
- `operation_controls_smoke.gd`: actual menu button signals and input events verify
  seed entry, New Operation, F3 reload, F9 seed display, firing/departure locks and
  grenade plus F3 within the same frame.
- `mission_flow_smoke.gd -- --operation-seed=1 --flank`: controller-driven walk through
  the narrowed flank, bunker, document interaction and extraction; enemies are
  removed to isolate traversal. Combat and live gunner behavior have separate tests.
- Existing movement, weapon, infantry, combat prototype, defensive MG, mission flow,
  presentation, fidelity, polish/settings, footsteps/mounted aim, combat feedback,
  cleared command post, infantry separation, handling/nests/perimeter and locomotion
  suites are retained. The old horizon assertion now counts spatial batches while
  preserving its continuous-bank/tree-population requirement.

Rendered evidence uses scripted Godot player/head aiming and actual viewport PNGs,
not a manual mouse walkthrough or fabricated screenshots. Isolated APPDATA and
LOCALAPPDATA under `.godot/validation/` keep the user's saved settings untouched.
Godot's existing Windows root-certificate-store diagnostic occurs independently of
these game systems; no network feature is used by this prototype.

## Performance and screenshots

Same Radeon 860M, Forward+ renderer, 1280×720 window, VSync disabled. Auto resolves
to Low (80% 3D scale); High uses full resolution and its existing advanced effects.
Each static stop warms for 45 frames and samples 90 rendered elapsed-frame times.
Actors/player movement are frozen; audio, presentation and rendering remain active.
This measures warmed static presentation, not worst-case combat or cold loading.
The original benchmark's weapon handling returned the camera to local zero each
frame; both comparison runs face north at the four identical positions. Screenshots
then aim the actual player/head at each subject independently of the benchmark.

| Preset / stop | Before median ms | After median ms | Before p95 ms | After p95 ms |
| --- | ---: | ---: | ---: | ---: |
| Auto / forest | 8.39 | 7.50 | 12.49 | 9.43 |
| Auto / fortification | 7.94 | 6.96 | 12.62 | 11.98 |
| Auto / interior | 7.67 | 6.19 | 12.88 | 11.69 |
| Auto / extraction | 5.58 | 4.09 | 10.37 | 8.61 |
| High / forest | 27.14 | 23.21 | 32.69 | 28.72 |
| High / fortification | 20.60 | 20.25 | 27.15 | 27.25 |
| High / interior | 22.10 | 20.84 | 27.22 | 27.60 |
| High / extraction | 18.42 | 16.05 | 22.03 | 21.84 |

Table: seed 1944 before/after. Across final seeds 1944, 1 and 73, median samples
range **4.09–8.15 ms Auto** and **15.93–25.59 ms High**. Median presentation cost
remains near or below the baseline across these samples. Tail timings vary: seed 73
Auto/interior reached 19.79 ms p95 in its short run. Spatial groups raise draw calls
(forest Auto 958→1,232) while reducing submitted primitives there (4.76M→4.54M;
extraction 1.46M→0.97M); some High views submit slightly more geometry than before.
Thermals, scheduling and short sample windows introduce variability; these are
measurements, not frame-rate guarantees. All 32 before/after samples, including
other seeds, draw counts and primitive counts: [raw CSV](operation_performance.csv).
A focused repeat of seed-73 Auto/interior, with 180 warm frames and 600 samples,
measured 6.39 ms median / 11.64 ms p95. The short-run spike did not persist in that
longer check; full-combat profiling remains a separate production task.

Thirty actual viewport captures are retained: three seeds × four mission views ×
Auto/High, plus seed-1 east/start/west boundaries on both tiers. Representative links:

| Subject | Auto | High |
| --- | --- | --- |
| Seed 1944 forest | [view](screenshots/operation_1944_auto_forest.png) | [view](screenshots/operation_1944_high_forest.png) |
| Seed 1 forest | [view](screenshots/operation_1_auto_forest.png) | [view](screenshots/operation_1_high_forest.png) |
| Seed 73 forest | [view](screenshots/operation_73_auto_forest.png) | [view](screenshots/operation_73_high_forest.png) |
| Seed 1 fortification | [view](screenshots/operation_1_auto_fortification.png) | [view](screenshots/operation_1_high_fortification.png) |
| Seed 73 radio room | [view](screenshots/operation_73_auto_interior.png) | [view](screenshots/operation_73_high_interior.png) |
| Seed 1944 extraction | [view](screenshots/operation_1944_auto_extraction.png) | [view](screenshots/operation_1944_high_extraction.png) |
| Eastern boundary | [view](screenshots/operation_1_auto_east_boundary.png) | [view](screenshots/operation_1_high_east_boundary.png) |
| Staging boundary | [view](screenshots/operation_1_auto_start_boundary.png) | [view](screenshots/operation_1_high_start_boundary.png) |
| Range/west boundary | [view](screenshots/operation_1_auto_west_boundary.png) | [view](screenshots/operation_1_high_west_boundary.png) |

Reviewed forest, fortification, interior, extraction and boundary views show planted
terrain/forest behind intended routes instead of exposed plane ends. This remains
procedural interim art: needle cards and repeated branches are visible, particularly
on Low; the report does not claim photorealistic foliage or exhaustive visual QA.

## Files and asset hooks

- New gameplay scripts: `mission_zone_option.gd`, `mission_zone_data.gd`,
  `mission_variant_catalog.gd`, `mission_variant.gd` under `scripts/gameplay/`.
- New native zone/catalog/restricted-navigation resources:
  `resources/missions/variants/`; optional log scene:
  `scenes/missions/variants/flank_restriction.tscn`.
- New presentation scripts: `forest_atmosphere.gd`, `forest_horizon.gd`,
  `variant_dressing.gd`; fixed weather resource: `resources/environments/`.
- Updated session, checkpoint, mission wiring, title menu/F9 audit, encounter cover
  anchors, forest presentation, perimeter, graphics profiles, shaders and materials.
- Updated original tree/plant mesh outputs in `assets/environments/germany/forest/`
  through `tools/build_forest_assets.gd`; existing credited texture pixels retained.
- New `tools/build_operation_catalog.gd`; updated `tests/bake_navigation.gd`;
  new operation tests/capture tool and targeted existing test extensions.
- Updated README, changelog, attribution and this report. Godot `.gd.uid` sidecars
  accompany scripts. No weapon, audio or character asset replacements were needed.

Rebuild authored data/geometry only after reviewing anchor changes:

```powershell
godot --headless --path . --script tools/build_operation_catalog.gd
godot --headless --path . --script tools/build_forest_assets.gd
godot --headless --path . --script tests/bake_navigation.gd -- --mission
godot --headless --path . --script tests/bake_navigation.gd -- --mission --restricted
godot --headless --path . --script tests/operation_variants_smoke.gd
godot --path . --script tests/operation_controls_smoke.gd
godot --path . --script tests/operation_capture.gd
godot --path . --script tests/operation_capture.gd -- --boundaries
```

## Remaining limitations and next phase

This remains an authored development level. Foliage cards, regular trunk branching,
some material repetition, geometric banks, small dressing intersections and simple
forest silhouettes still need artist polish. The beyond-gate road is scenery; the
mission completes at the rendezvous rather than providing a drivable destination.
No terrain topology, building floor plan, objective chain or enemy count is randomized.
All finite options and both collision maps are tested; this is not exhaustive manual
testing of every possible seed or off-route camera exploit.

Existing characters, weapons, animation and synthesized effects remain interim.
English/German speech recording slots remain empty. Checkpoints are session-only;
living enemies and supplies reset on reload, preserving previous behavior. Final
performance must be profiled during full firefights on target devices, including
frame pacing, thermal limits and production assets.

The next phase should concentrate on production foliage/terrain art, grounded prop
placement, licensed voice and authentic sound recordings, animation and encounter
polish using these existing systems, rather than adding more foundational systems.
