# Asset attribution and provenance

## External assets included

The character iteration additionally includes **Rigged Lowpoly WW2 Soldier** by
**nisu**, CC0 1.0, verified on the author's OpenGameArt entry on 2026-09-10:
https://opengameart.org/content/rigged-lowpoly-ww2-soldier
Download: https://opengameart.org/sites/default/files/lowpolysoldier.zip
License: https://creativecommons.org/publicdomain/zero/1.0/
Original FBX and texture: `assets/characters/source/LowpolySoldier/`.
`tools/retarget_soldier.gd` converts the weighted rest geometry into the shared
17-bone rig, combines/normalizes weights and poses arms for weapon carrying.
Faction materials recolor clothing; original project helmets, gaiters and equipment
differentiate the configurations. This is an adapted low-detail donor uniform,
not a claim of museum-accurate Allied tailoring or final photorealistic characters.

Downloaded 2026-09-10 from Poly Haven's official asset CDN. All four texture sets
are **CC0 1.0 Universal**, permitting commercial use, modification and redistribution.
License verified at https://polyhaven.com/license and each linked asset page.
License text: https://creativecommons.org/publicdomain/zero/1.0/legalcode

| Asset | Source | Local directory | Included maps |
| --- | --- | --- | --- |
| Forest Ground 04 | https://polyhaven.com/a/forest_ground_04 | `assets/textures/polyhaven/forest_ground_04/` | 1K diffuse, OpenGL normal, roughness JPG |
| Bark Brown 02 | https://polyhaven.com/a/bark_brown_02 | `assets/textures/polyhaven/bark_brown_02/` | 1K diffuse, OpenGL normal, roughness JPG |
| Concrete Wall 003 | https://polyhaven.com/a/concrete_wall_003 | `assets/textures/polyhaven/concrete_wall_003/` | 1K diffuse, OpenGL normal, roughness JPG |
| Rock Boulder Dry | https://polyhaven.com/a/rock_boulder_dry | `assets/textures/polyhaven/rock_boulder_dry/` | 1K diffuse, OpenGL normal, roughness JPG |

Original downloaded pixels are retained. Godot materials adjust color, scale,
normal strength and roughness; the soil shader blends an irregular muddy trail
and wheel ruts. No Poly Haven API is used at runtime or required by the project.
Download URL pattern:
`https://dl.polyhaven.org/file/ph-assets/Textures/jpg/1k/{asset}/{asset}_{map}_1k.jpg`.

Downloaded 2026-09-11 from the same Poly Haven CDN, verified CC0 1.0 on each
linked asset page. Replace flat command-post furniture/dressing color with
photographic detail; wood/metal weapon parts and tree trunks keep their
existing procedural/bark materials, which suit small primitive and rod shapes
better than a tiled photo.

| Asset | Source | Local directory | Included maps |
| --- | --- | --- | --- |
| Metal Plate | https://polyhaven.com/a/metal_plate | `assets/textures/polyhaven/metal_plate/` | 1K diffuse, OpenGL normal, roughness JPG |
| Worn Planks | https://polyhaven.com/a/worn_planks | `assets/textures/polyhaven/worn_planks/` | 1K diffuse, OpenGL normal, roughness JPG |
| Rough Linen | https://polyhaven.com/a/rough_linen | `assets/textures/polyhaven/rough_linen/` | 1K diffuse, OpenGL normal, roughness JPG |
| Fir Tree 01 (twig maps only) | https://polyhaven.com/a/fir_tree_01 | `assets/textures/polyhaven/fir_twig/` | 1K twig diffuse, cutout alpha PNG, OpenGL normal JPG |
| Grass Medium 01 (maps only) | https://polyhaven.com/a/grass_medium_01 | `assets/textures/polyhaven/ground_plants/` | 1K diffuse, cutout alpha PNG, OpenGL normal JPG |
| Fern 02 (maps only) | https://polyhaven.com/a/fern_02 | `assets/textures/polyhaven/ground_plants/` | 1K diffuse, cutout alpha PNG, OpenGL normal JPG |

Grass Medium 01 and Fern 02 are likewise used for their **textures only**; the
project's generated ground-cover geometry is retained and the photographic tufts and
fronds are mapped onto it. `TUFTS` and `FERNS` in `tools/build_forest_assets.gd` select
sub-rectangles of each atlas — the grass atlas holds dense tufts along its lower edge
and single blades above, and only the tufts suit a ground-cover card.
`shaders/ground_plant.gdshader` replaces the untextured vertex-colour foliage shading
for grass, ferns and shrubs.

Only the twig **textures** are taken from Fir Tree 01; its mesh is not used. That
asset's geometry is a film/archviz scan of 8M+ triangles whose glTF buffer is roughly
950 MB at every offered resolution (the 1K-8K options change texture size only), which
is orders of magnitude above a real-time foliage budget. The project's own procedural
tree geometry is retained and these photographic needle sprigs are mapped onto it.
`tools/pack_twig_atlas.gd` packs the separate cutout map into the diffuse alpha channel
so `shaders/needle_branch.gdshader` samples one atlas instead of two; the packed result
is `assets/textures/fir_twig_packed.png`. The atlas holds seven sprigs plus bark strips,
so `SPRIGS` in `tools/build_forest_assets.gd` maps each leaf card to one sprig
sub-rectangle rather than the full UV range. The supplied roughness map is near-uniform
and was dropped in favour of a shader constant.

Wired into `assets/materials/presentation/{worn_metal,worn_planks,field_canvas}.tres`
(triplanar `StandardMaterial3D`, same pattern as the original four sets) and used by
`command_post_dressing.gd` (furniture, fixtures, sandbags, camouflage scrim) and the
mission crate/supply dressing in `mission_perimeter.gd` / `mission_presentation.gd`.

## Original project assets

The constrained-operation iteration adds **no external downloads or licenses**.
Zone/anchor resources, the log restriction, fixed overcast atmosphere, terrain-bank
geometry, rear trail mask, seeded dressing and spatial horizon layout are original
project work. `tools/build_forest_assets.gd` revises the original three tree variants
and their LODs; the existing original spruce atlas is retained with tapered shader
silhouettes. Ground blending/detail normals reuse the four credited Poly Haven CC0
sets above without replacing their source pixels. Broad timber/metal patina is
procedural original shading. Screenshots are actual Godot renders of this project.
No external sky, foliage pack, voice recording, animation or proprietary game asset
was incorporated. See `docs/OPERATION_VARIANTS_VALIDATION.md` for remaining art needs.

The handling/nest/perimeter iteration adds no external assets. Handling resources,
magazine/charging-handle motion, grip-target skeletal posing, stance/ground adaptation,
perimeter berm geometry and extraction gate are original project work. The forest
backdrop reuses the existing original tree LOD meshes; berms and timber reuse the
previously credited materials. No new voice recordings or licensed sound pack were
installed. These procedural animations and meshes remain production-replacement hooks.

The combat-feedback iteration adds no external assets. New authored sound cues
(`canopy`, `gust`, `radio_bed`, `radio_signal`, `hit_flesh`, `hit_gear`) and revised
explosion/loop PCM are produced by `tools/build_audio_assets.gd`. Radio signals are
nonverbal oscillator/noise effects, not fabricated German radio speech. Seamless
loop joins are overlap-added offline. Procedural cloud and damage-vignette shaders,
particle effects and distance-driven leg posing are original project work.
These remain sound-design/animation placeholders pending authentic licensed
recordings, production animation and human mixing review.

The targeted polish pass adds **no external downloads**. Original new assets:
`assets/textures/spruce_branch.png` (deterministically drawn needle/twig atlas,
`tools/build_needle_atlas.gd`), revised tree meshes/cards, crafted sandbag/limb/concrete
meshes, worn wood/metal shaders, anatomically shaped interim heads and face shader,
cloud-layer revisions and non-speech two-note dialogue diagnostics. None are scans,
sampled speech or extracted game assets. The original diagnostic tone is opt-in;
the game still contains no English/German speech recordings. Exact production needs
and import paths: `docs/VOICE_RECORDING_MANIFEST.md`.

- Branched conifer/deciduous meshes, roots, ferns, grasses and irregular rocks:
  `tools/build_forest_assets.gd`, baked into `assets/environments/germany/forest/`.
  Their assigned bark/rock materials use the CC0 maps credited above.
- Weapon details, equipment and field-uniform mannequin:
  `tools/build_equipment.gd`. These are original geometric approximations, not
  scans or models extracted from another game. Uniform and weapon models remain
  interim assets requiring professional modeling, rigging and animation.
- Command-post furniture, radios, telephone, crates, revetments, wire, sandbags,
  camouflage strips, signs and fixtures: `scripts/presentation/command_post_dressing.gd`.
- `assets/props/operations_map.svg`: original fictional cartography, not a copied
  historical map or film/game prop. German labels are contextual, non-ideological.
- Layered sound effects and ambience: `tools/build_audio_assets.gd`, rendered to
  `assets/audio/designed/*.res` (native AudioStreamWAV PCM resources). Entirely
  synthesized from noise/oscillators; no external recordings or generated speech.
- Native system fonts are requested by name for the menu; no font files are bundled.
  Godot's default font is the fallback.

No third-party weapon models, music, recorded dialogue, proprietary game assets or
commercial-film assets were incorporated. The CC0 character above is the only
additional external asset in the character iteration.

## Recording and final-art requirements

The authored effects are functional sound-design placeholders, not authentic
recordings. Replace them with legally cleared recordings of M1911, P38, Thompson,
MP40, StG 44, M1919 and MG42 reports; launcher launches; mechanisms and weapon-specific
reloads; dirt/wood/concrete/metal impacts and footsteps; grenade/rocket explosions;
forest wind/birds/insects; distant artillery/gunfire; bunker ventilation/electrics.

`resources/characters/{allied,german}_voice.tres` each contain eight combat event
categories plus a radio briefing, subtitle keys, fallback text, timing and a separate
empty recording dictionary. All categories have gameplay routes and share actor,
category and global scheduling. Missing recordings are silent. No gibberish or
synthesized German speech is played. Obtain authentic licensed/native-speaker
recordings and a fluent review of context/timing before production. Recordings can
be assigned directly to the matching event key without changing gameplay code.

Original additions: shared rig/animation library and faction equipment builder,
first-person hand geometry, overcast cloud shader, uniform shaders, impact masks,
smoke/particles and lower-detail tree meshes. No external sky or voice asset was
downloaded. The original synthesis assets remain sound effects only.

Final mesh needs: scanned/authored foliage with production LODs; sculpted terrain;
beveled and accurately textured weapons with hands; rigged faction uniforms/faces;
authentic radios/telephones and richer furniture; camouflage fabric and wire detail.
