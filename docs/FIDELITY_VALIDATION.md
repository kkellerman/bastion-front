# Character, Voice, Forest and Combat Fidelity — validation

Godot 4.7.2 stable, Windows, Vulkan Forward+, AMD Radeon 860M, 1280×720,
VSync enabled, atmospheric graphics tier. Samples are warm static views, 100
warmup frames followed by 90 timed frames. AI is frozen for consistent rendering
comparisons. These are not minimum combat FPS or a cross-hardware guarantee.

| View | FPS | Draw calls | Rendered primitives |
| --- | ---: | ---: | ---: |
| Forest start | 59.9 | 969 | 1,405,142 |
| Bunker approach | 60.1 | 1,572 | 394,614 |
| Radio room | 59.9 | 1,412 | 362,698 |
| Operations room | 60.0 | 601 | 177,117 |

The preceding forest pass measured approximately 52–59 FPS and 1,930,592
primitives. The new near/far tree tiers reduce geometry while increasing nearby
crown density. Counts include rendering passes, not just unique mesh triangles.

## Commands and coverage

```powershell
godot --headless --path . --editor --import --quit
godot --headless --path . --script tests/bake_navigation.gd -- --mission
godot --path . --script tests/movement_smoke.gd
godot --headless --path . --script tests/weapon_smoke.gd
godot --headless --path . --script tests/infantry_smoke.gd
godot --headless --path . --script tests/combat_prototype_smoke.gd
godot --headless --path . --script tests/defensive_mg_smoke.gd
godot --path . --script tests/mission_flow_smoke.gd
godot --path . --script tests/presentation_smoke.gd
godot --headless --path . --script tests/fidelity_smoke.gd
godot --path . --script tests/presentation_capture.gd
godot --path . --script tests/character_capture.gd
```

All listed smoke suites passed with zero failures. Import, mission launch,
captures and the 1,446-polygon navigation bake completed. The mission-flow suite
physically walks the forest/trench/interior route, mounts/dismounts a gun, retrieves
documents, extracts and restarts using injected inputs. Combat suites separately
exercise live infantry/MG attacks, all weapons, projectile damage and cover.

Fidelity tests verify both factions' skeleton/skin/clip interfaces, normalized
retargeted weights, actual animated thigh pose, matching voice language,
actor/category/global cooldowns, cloud sky and distant tree presence, east flank
connectivity, shared alerts, bounded evidence-based search, cover occlusion,
checkpoint magazines/objectives and actual death/Enter scene restoration, FOV
integration and hands on all seven carried weapons.

Reviewed captures are retained in `docs/screenshots/`: title_menu.png, forest.png,
bunker.png, operations.png, combat.png and characters.png. Character captures
deliberately expose the interim low-detail asset quality. Gameplay scenes use the
same models; these are not promotional renders or final-art claims.

The restricted environment emits the existing `Failed to read the root certificate
store` startup diagnostic. No project parser, missing-reference, shader or runtime
errors remained in the final runs. Audio was exercised with native windowed tests;
headless Dummy runs retain simulation events and omit inaudible PCM playback.

## Limits requiring human/art review

Recorded English/German voice slots are empty, so speech/briefings are silent with
timed subtitles. Recording playback accepts proper AudioStream resources but cannot
be judged for performance/delivery until licensed voice sessions are supplied.
Source character topology is low-poly; animation, facial detail, uniform tailoring,
finger contact, reload choreography and visual LOD transitions need production
polish. Tactical balance, audio mix and motion comfort still need human playtesting.
Checkpoints are session-only and reset live enemies and supply availability.
