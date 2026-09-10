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

## Original project assets

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
