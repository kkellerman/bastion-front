# Production dialogue recording manifest

**No English or German speech recordings are included.** Normal gameplay displays
`[Voice recording missing]` before subtitles for empty slots. F10 states the same
limitation. The optional **Voice diagnostic tones (NON-SPEECH test clips)** setting
plays an original two-note tone through the actual spatial dialogue path and marks
the subtitle `[NON-SPEECH VOICE TEST]`. These tones are not language or voice acting.

Provide these 18 licensed recordings, with native/fluent German delivery and a
fluent review of the German script. The authoritative text and subtitle keys live
in `resources/characters/allied_voice.tres` and `german_voice.tres`.

| Event / basename | Allied file | German file | Gameplay route |
| --- | --- | --- | --- |
| spotting | `assets/audio/voice_allied/spotting.wav` | `assets/audio/voice_german/spotting.wav` | Visible contact enters alert |
| taking_fire | `assets/audio/voice_allied/taking_fire.wav` | `assets/audio/voice_german/taking_fire.wav` | Infantry hurt / player health decreases |
| reloading | `assets/audio/voice_allied/reloading.wav` | `assets/audio/voice_german/reloading.wav` | Equipped or NPC weapon starts reload |
| moving | `assets/audio/voice_allied/moving.wav` | `assets/audio/voice_german/moving.wav` | Chase/advance state |
| lost_sight | `assets/audio/voice_allied/lost_sight.wav` | `assets/audio/voice_german/lost_sight.wav` | Visual contact lost / search context |
| grenade_warning | `assets/audio/voice_allied/grenade_warning.wav` | `assets/audio/voice_german/grenade_warning.wav` | Explosive within 9 m |
| casualty | `assets/audio/voice_allied/casualty.wav` | `assets/audio/voice_german/casualty.wav` | Nearby allied actor dies |
| death | `assets/audio/voice_allied/death.wav` | `assets/audio/voice_german/death.wav` | Actor/player dies; interrupts current line |
| briefing | `assets/audio/voice_allied/briefing.wav` | `assets/audio/voice_german/briefing.wav` | Mission start, skipped on checkpoint restore |

Use dry, mono WAV, preferably 48 kHz PCM, no loop and minimal leading silence.
Keep voice levels consistent; target approximately -18 LUFS with headroom, then
audition in the actual mix. Do not bake bunker reverb into the recording. Keep a
license/release record naming the performer, rights holder, source, permitted game
distribution and modifications. Update ASSET_ATTRIBUTION.md when importing them.

Files with these names are discovered through each voice resource's
`recording_directory` after Godot imports them. Alternatively assign an AudioStream
to `recordings[event]`; explicit assignments take precedence. No gameplay changes
are needed. Text keys and recording paths remain separate for localization.

Playback is an AudioStreamPlayer3D attached to the actor at head height, 30 m maximum
distance, on Dialogue outdoors or DialogueInterior -> Dialogue indoors. F10's
Dialogue volume controls both. Cooldowns: actor 5 s, actor/category 16 s,
shared/category 10 s, global stream duration (minimum 2.4 s) + 0.4 s. Normal events
can be suppressed by these limits; casualty requests expire after 8 s. Death
interrupts the active line, bypasses combat cooldowns, and clears queued speech.

To hear the pipeline now: enable diagnostic tones in F10, return to the mission,
wait for the briefing/channel cooldown, fire and reload. F1/F2 change faction;
Allied and German diagnostics use distinct pitches solely to identify routing.
`tests/polish_smoke.gd` measures nonzero native audio-mixer samples for every combat
category in both factions, checks cooldowns, a supplied recording resource,
interior routing, death priority and scene cleanup. This proves routing, not spoken
language authenticity, intelligibility, pronunciation or final voice quality.
