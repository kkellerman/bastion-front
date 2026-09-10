# Bastion Front — Godot Starter Specification

## Project Goal
Build **Bastion Front**, a modern, photorealistic single-player FPS set in Europe during World War II, inspired by the compact, readable combat and level progression of classic shooters while using original maps, missions, characters, dialogue, and game assets.

The visual target should evoke the grounded readability of **Day of Defeat: Source**, but with substantially more modern rendering, materials, lighting, animation, audio, environments, and character detail.

The player can choose to play missions from either:
- **Allied side**
- **German side**

The project should treat both as historically grounded military factions rather than simple palette swaps. Each side should have its own uniforms, weapons, spoken language, equipment, HUD identifiers, mission context, and appropriate environmental details.

Primary design goals:
- Modern photorealistic 3D presentation
- Grounded WWII European environments
- Responsive, uncomplicated FPS controls
- Compact to medium-size mission maps rather than giant open worlds
- Historically inspired weapons and equipment
- Selectable Allied and German campaigns/missions
- Authentic German-language dialogue for German units
- Authentic English-language dialogue for Allied units
- Low implementation complexity and highly modular game systems
- Easy incremental development through AI-assisted coding

## Title, Branding, and Opening Presentation

The working title of the game is **Bastion Front**. All title-screen, main-menu, loading-screen, and build-label references should use this name unless explicitly changed later.

### Title Screen
The title screen should immediately establish a grounded, gritty World War II tone. It should feel cinematic, serious, and atmospheric rather than arcade-like or heroic-fantasy styled.

Required title-screen elements:
- Large **BASTION FRONT** wordmark
- World War II European battlefield imagery or an in-engine rendered scene
- A restrained, military-style menu treatment
- Subtle environmental motion such as drifting smoke, mist, rain, falling ash, moving tree branches, searchlights, or distant artillery flashes
- Period-authentic equipment, vehicles, uniforms, architecture, and battlefield dressing appropriate to the chosen background scene
- Minimal UI animation; avoid flashy modern esports presentation

Suggested visual backdrop concepts:
- A misty German forest with a partially concealed concrete bunker and field telephone lines
- A rain-soaked command post perimeter at dusk
- Allied infantry moving cautiously through a damaged European village
- A silhouetted MG42 bunker position with smoke and artillery flashes in the distance
- A dim command-post map room visible through an open bunker doorway

The title screen should not depict Nazi ideology as triumphant or celebratory. Historical symbols may appear when contextually appropriate, but the emphasis should be on the wartime environment, soldiers, fortifications, tension, and human-scale conflict.

### Main Menu Example

```text
BASTION FRONT

NEW GAME
    ALLIED CAMPAIGN
    GERMAN CAMPAIGN

MISSION SELECT
OPTIONS
CREDITS
QUIT
```

### Cinematic Tone
Aim for the **gritty, desaturated, documentary-like atmosphere associated with serious WWII combat dramas**, including the visual language commonly associated with works such as *Band of Brothers* and *Saving Private Ryan*, without directly reproducing their shots, characters, scenes, music, or proprietary visual assets.

Key characteristics:
- Muted greens, browns, greys, khakis and weathered steel tones
- Restrained saturation rather than colorful game-like grading
- Strong contrast in selected scenes, but preserve gameplay readability
- Natural overcast and low-angle sunlight
- Mist, rain, mud, smoke, dust and battlefield haze
- Handheld-feeling camera motion only for cinematics; player camera should remain comfortable and readable
- Subtle film-grain-style post-processing if it does not reduce clarity
- Realistic exposure transitions from dark interiors to daylight
- Dirt, wear, chipped paint, mud, soot and moisture on materials
- Convincing battlefield clutter without excessive visual noise
- Serious, grounded soundscape rather than exaggerated action-movie presentation

The goal is **modern photorealistic WWII immersion with a gritty cinematic character**, not a literal recreation of any particular film or television production.

## Historical Presentation

The setting is WWII-era Europe under the Third Reich and Allied campaigns against it. Historical symbols, uniforms, ranks, signage, flags, architecture, and propaganda may appear where appropriate to the setting and mission context.

The presentation should aim for historical authenticity rather than celebration or glorification of Nazi ideology. German-side missions should portray soldiers as members of the German wartime military structure rather than turning political ideology into a gameplay reward system.

Where practical, research historical details before finalizing:
- Uniform cuts and colors
- Rank insignia
- Unit equipment
- Weapon issue patterns
- Vehicles
- Signage
- Architecture
- Spoken terminology
- Radio procedure
- Geography

## Recommended Core Stack

### Engine
- **Godot 4.7.x**
- Renderer: **Forward+**
- Primary development target: Windows PC
- Target API: Vulkan

### Language
- **Typed GDScript** for gameplay systems
- Avoid C# until a specific performance or integration need appears
- Use shaders only when necessary for visual effects that standard materials cannot provide

### Development Tools
- Godot editor — scenes, materials, lighting, animation, navigation, level assembly
- Cursor or VS Code — GDScript and AI-assisted development
- Git + GitHub — source control
- Blender — custom models, rigging, UV work, animation, asset cleanup
- Substance 3D Painter or equivalent — optional high-end PBR texturing
- Audacity/Reaper — sound cleanup and voice processing

### Asset Formats
- Models/animations: **GLB / glTF 2.0**
- Textures: PNG/TGA/source PSD or equivalent
- PBR maps: albedo/base color, normal, roughness, metallic, AO when needed
- Audio: WAV masters, OGG where appropriate for shipping

---

# Art Direction

## Visual Target
The game should **not** look retro or intentionally pixelated. It should visually support the **Bastion Front** identity: gritty, cinematic, grounded, weathered, and photorealistic.

Visual benchmark:

```text
Day of Defeat: Source
        +
modern PBR materials
        +
high-resolution photogrammetry-quality environments
        +
modern character models
        +
volumetric atmosphere
        +
realistic weapon animation
        +
modern particles / decals / lighting
```

Target a convincing modern-indie photorealistic FPS with serious WWII cinematic atmosphere rather than trying to match the production scale of a current AAA Call of Duty or modern Wolfenstein game.

Prioritize:
- Physically based materials
- High-resolution environment textures
- Realistic stone, plaster, brick, concrete, timber, steel, glass, mud and vegetation
- Dynamic shadows
- Baked lighting where it improves quality/performance
- Volumetric fog and atmospheric haze
- Smoke, dust, embers, fire and debris
- Bullet impacts and surface-specific decals
- Realistic weapon models
- High-detail character uniforms
- Period-authentic props
- Proper interior/exterior exposure balance
- Good sound design

Cinematic image treatment:
- Prefer slightly desaturated, naturalistic color grading
- Preserve readable skin tones, uniforms, terrain, and target silhouettes
- Use volumetric fog, smoke and atmospheric perspective to add depth
- Allow subtle camera shake from nearby artillery/explosions, but keep aiming comfortable
- Use environmental weather and battlefield effects as mood, not constant screen obstruction

Avoid:
- Pixel-art shaders
- Deliberately low-resolution textures
- PS1/Quake-style vertex wobble
- Sprite-based enemies
- Cartoon proportions
- Exaggerated neon HUD elements

---

# Environment Asset Strategy

Use modular environment kits combined with custom hero assets.

## Core European Environments
Build or source modular sets for:
- French villages
- Belgian villages
- Dutch towns
- German towns
- Normandy countryside
- Hedgerows
- Farmhouses and barns
- Churches
- Railway stations
- Industrial facilities
- Military bunkers
- Trenches
- Fortifications
- Barracks
- Warehouses
- Stone castles
- Government buildings
- Urban streets
- Bridges
- Dense Central European conifer forests
- Forest roads and military tracks
- Forest bunker/command-post complexes
- Snow-covered villages and forests

## Important Environment Props
- Sandbags
- Barbed wire
- Czech hedgehogs
- Wooden crates
- Ammunition boxes
- Fuel drums
- Radios
- Field telephones
- Maps
- Desks
- Typewriters
- Filing cabinets
- Barracks furniture
- Street signs
- Posters
- Flags/banners where historically appropriate
- Searchlights
- Anti-tank obstacles
- Destroyed vehicles
- Rubble
- Artillery shells
- Helmets and personal equipment

Prefer modular pieces using standardized dimensions so maps can be assembled rapidly inside Godot.

---

# Character Model Framework

## Shared Character Architecture
Use one common humanoid gameplay skeleton whenever possible.

```text
CharacterBase
├── Skeleton3D
├── Body mesh
├── Uniform mesh
├── Head
├── Equipment
├── Weapon socket
└── AnimationTree
```

Faction appearance is driven by data rather than separate codebases.

## Allied Characters
Potential visual variants:
- U.S. Army infantry
- U.S. airborne troops
- British infantry
- British airborne troops
- Optional additional Allied forces later

Typical equipment can include:
- M1 helmet
- Web gear
- Ammunition pouches
- Canteen
- Field pack
- Bayonet/knife
- Grenades

## German Characters
German characters should use historically plausible:
- Uniform colors and materials
- Tunics
- Trousers
- Boots
- Helmets
- Field gear
- Ammunition pouches
- Belts
- Rank insignia
- Unit distinctions when appropriate

Do not use generic modern tactical gear.

German variants can include gameplay roles such as:
- Rifleman
- MP40-equipped assault soldier
- MP44/StG 44-equipped assault soldier
- Officer/NCO
- Machine-gun crew
- Anti-tank soldier

Use shared rigs and animation sets wherever possible so clothing and equipment can be swapped without duplicating the underlying AI or animation code.

---

# Faction System

Create a `FactionData` Resource.

Suggested values:

```text
Faction.ALLIES
Faction.GERMAN
```

`FactionData` should define:
- faction_id
- display_name
- language
- default_uniform_set
- weapon_pool
- grenade_type
- anti_tank_launcher
- mounted_machine_gun
- voice_set
- UI iconography
- friendly/enemy relationship table

Do **not** hard-code Allied/German checks throughout individual scripts.

Example concept:

```gdscript
class_name FactionData
extends Resource

@export var faction_id: StringName
@export var display_name: String
@export var spoken_language: StringName
@export var default_weapon_ids: Array[StringName]
@export var grenade_id: StringName
@export var launcher_id: StringName
@export var mounted_mg_id: StringName
```

---

# Language and Voice System

## German Side
German personnel should speak **natural German**, not English with a German accent.

Examples of situations requiring German dialogue:
- Enemy spotted
- Taking fire
- Reloading
- Throwing grenade
- Officer commands
- Retreat/fallback
- Suppression
- Friendly casualty
- Searching for player
- Calling for support

Keep dialogue context-sensitive and short enough for combat.

Use native or professionally fluent German voice actors for final production whenever practical.

Store spoken lines separately from subtitles:

```text
voice/german/
voice/allied_english/
```

Subtitle architecture should support localization independently of voice audio.

## Allied Side
Default Allied voice language:
- English

Additional Allied languages can be added later when appropriate to a mission.

---

# Player Framework

Use `CharacterBody3D`.

Initial controls:
- WASD movement
- Mouse look
- Sprint
- Crouch
- Jump only where appropriate
- Interact
- Fire
- Aim down sights
- Reload
- Grenade
- Weapon switching

Avoid initially adding:
- Sliding
- Wall running
- Grappling
- Hero abilities
- Complicated skill trees

Movement should feel grounded but responsive.

---

# Weapon Framework

Use a **data-driven weapon system**.

Create `WeaponData` Resources containing:
- weapon_id
- display_name
- faction
- weapon_class
- damage
- rate_of_fire
- magazine_capacity
- reserve_ammo_type
- reload_time
- recoil
- spread
- effective_range
- hitscan_or_projectile
- projectile_scene
- viewmodel_scene
- world_model_scene
- muzzle_audio
- reload_audio

Gameplay classes should not contain faction-specific weapon assumptions.

## Core Handheld Weapon Classes

### Knife / Melee
Both factions:
- Combat/utility knife appropriate to equipment set

Possible later differentiation can be cosmetic unless gameplay warrants otherwise.

### Pistols
Faction-authentic pistols can be added as specific weapon resources.

Examples:

**Allied**
- M1911

**German**
- P38
- Luger P08 where mission/equipment context makes sense

### Submachine Guns

**Allied**
- Thompson

**German**
- MP40

### Assault Rifle

**German**
- MP44 / StG 44

For gameplay balance, an Allied rifle or automatic-rifle counterpart may be introduced separately rather than inventing an ahistorical Allied assault rifle.

Potential Allied primary weapons later:
- M1 Garand
- M1 Carbine
- BAR

### Grenades

**Allied**
- Mk 2 fragmentation grenade ("pineapple")

**German**
- Stielhandgranate (stick grenade)

Grenades use physical projectile scenes with:
- Fuse
- Bounce
- Collision
- Explosion radius
- Damage falloff
- Fragmentation approximation
- Audio/particle effects

### Anti-Tank / Rocket Weapons

**Allied**
- Bazooka

**German**
- Panzerfaust

These should operate as projectile weapons rather than hitscan weapons.

Differentiate them in handling rather than simply reskinning the same gun.

---

# Fixed Machine-Gun Emplacements

Portable machine guns are **not player-carried weapons in the initial version**.

Machine guns exist only at fixed or deployable map positions.

## Allied
- **M1919 .30 caliber machine gun**

## German
- **MG42**

Mounted MG scene:

```text
MountedMachineGun
├── StaticBody3D / mount
├── PivotYaw
│   └── PivotPitch
│       ├── WeaponModel
│       ├── Muzzle
│       └── InteractionPoint
├── Audio
└── Heat / firing system
```

Features:
- Player can mount/dismount
- Restricted horizontal firing arc
- Restricted vertical firing arc
- High sustained fire rate
- Heat or barrel-management mechanic optional
- Infinite or large ammunition pool configurable per emplacement
- NPCs can optionally operate emplacements later

The MG42 should sound and feel markedly different from the Allied .30 cal.

---

# Weapon Scene Architecture

A first-person weapon may use:

```text
WeaponViewModel (Node3D)
├── Arms
├── WeaponMesh
├── AnimationPlayer
├── Muzzle
├── MuzzleFlash
├── ShellEjectionPoint
└── Audio
```

Keep first-person weapon models separate from world models.

This enables higher-detail first-person assets without unnecessarily increasing world-scene complexity.

---

# Interaction System

Use a short `RayCast3D` from the player's camera.

Interactable objects should share a consistent contract.

Use for:
- Doors
- Mounted machine guns
- Buttons
- Switches
- Ammo crates
- Mission objectives
- Radios
- Vehicles later
- Ladders where necessary

---

# Damage System

Create reusable components:

```text
HealthComponent
DamageReceiver
ArmorComponent (optional)
HitboxComponent
```

Character hit regions can include:
- Head
- Torso
- Arms
- Legs

Use configurable damage multipliers rather than embedding damage logic inside enemy scripts.

Avoid overly complicated ballistics for v0.1.

Start with hitscan small arms and projectile explosives.

---

# Enemy and Friendly AI

Use the same base AI framework for both factions.

The player's faction determines who is friendly and hostile.

Basic state machine:

```text
IDLE
  ↓
PATROL
  ↓
ALERT
  ↓
ENGAGE
  ↓
TAKE_COVER
  ↓
SEARCH
  ↓
RETURN / PATROL
```

Use `NavigationAgent3D` for movement.

Initial sensing:
- Distance
- Field of view
- Line-of-sight raycast
- Hearing radius
- Gunfire events
- Explosion events

Later tactical behaviors:
- Use cover
- Suppression
- Flank
- Grenade response
- Retreat
- Call nearby allies
- Mounted MG use
- Officer/NCO command influence

Avoid building sophisticated squad AI until basic combat is fun.

---

# Mission / Campaign Framework

The game should allow the player to select a faction before entering a campaign or mission set.

Example main menu:

```text
BASTION FRONT

NEW GAME

    ALLIED CAMPAIGN

    GERMAN CAMPAIGN

OPTIONS
CREDITS
QUIT
```

Each campaign contains original missions set against historically plausible WWII European operations.

Use `MissionData` Resources:
- mission_id
- title
- year
- location
- faction
- briefing
- player_loadout
- friendly_units
- opposing_faction
- level_scene
- objectives
- weather
- time_of_day

Avoid embedding mission story data directly in level scripts.

---

# Level Design Philosophy

Levels should combine classic FPS readability with believable spaces.

Good mission locations:
- Village assault
- Farmhouse defense
- Railway sabotage
- Bunker infiltration
- Bridge defense/destruction
- Industrial complex
- Forest ambush
- Urban street fighting
- Castle/fortification assault
- Snow-covered defensive line

A typical early mission should contain:
- One primary objective
- One secondary objective
- Several combat spaces
- At least two alternate routes
- Interior and exterior transitions
- Ammunition resupply points
- One mounted MG position
- Environmental storytelling
- Clear end condition

Avoid huge open worlds.

---

# Pickups / Supplies

Possible pickups:
- Health kit
- Bandage
- Ammunition
- Grenades
- Weapon pickup
- Mission item
- Documents

Avoid arcade treasure/score pickups unless the final game direction calls for them.

---

# UI

Initial HUD:
- Health
- Ammunition
- Grenade count
- Current weapon
- Crosshair where appropriate
- Interaction prompt
- Objective indicator

Optional realism setting can reduce HUD elements.

Faction UI styling should remain readable and period-inspired without reducing usability.

---

# Audio

Audio is a major quality target.

Needed early:
- Distinct firearm reports
- Indoor/outdoor firearm acoustics
- Bullet impacts by material
- Ricochets
- Grenade explosions
- Footsteps by surface
- Weapon handling
- Reloads
- Shell casings
- Doors
- Distant artillery
- Aircraft ambience
- Vehicle ambience
- Wind/rain/snow environment loops
- German combat dialogue
- Allied combat dialogue

Use occlusion/reverb zones where practical for interiors, bunkers, tunnels and exterior spaces.

---

# Suggested Directory Structure

```text
res://
├── assets/
│   ├── characters/
│   │   ├── allied/
│   │   └── german/
│   ├── environments/
│   │   ├── france/
│   │   ├── germany/
│   │   ├── low_countries/
│   │   ├── military/
│   │   └── generic_europe/
│   ├── materials/
│   ├── props/
│   ├── textures/
│   ├── weapons/
│   │   ├── allied/
│   │   └── german/
│   └── audio/
│       ├── weapons/
│       ├── ambience/
│       ├── voice_allied/
│       └── voice_german/
│
├── scenes/
│   ├── player/
│   ├── characters/
│   ├── weapons/
│   ├── mounted_weapons/
│   ├── pickups/
│   ├── interactables/
│   ├── missions/
│   └── ui/
│
├── scripts/
│   ├── components/
│   ├── gameplay/
│   ├── ai/
│   ├── weapons/
│   ├── factions/
│   └── systems/
│
├── resources/
│   ├── factions/
│   ├── weapons/
│   ├── characters/
│   ├── missions/
│   └── items/
│
├── shaders/
├── localization/
└── tests/
```

---

# Coding Conventions

Use typed GDScript wherever practical.

Example:

```gdscript
class_name HealthComponent
extends Node

signal died
signal health_changed(current: float, maximum: float)

@export var max_health: float = 100.0
var current_health: float

func _ready() -> void:
    current_health = max_health

func take_damage(amount: float) -> void:
    if amount <= 0.0 or current_health <= 0.0:
        return

    current_health = max(current_health - amount, 0.0)
    health_changed.emit(current_health, max_health)

    if current_health == 0.0:
        died.emit()
```

Rules:
- Prefer composition over deep inheritance
- Keep scripts focused
- Use Resources for weapon/faction/mission configuration
- Use signals to reduce coupling
- Avoid faction-specific branches throughout generic systems
- Avoid giant manager classes
- Avoid premature optimization
- Keep gameplay independent of final art assets
- Prefer reusable scenes
- Do not hard-code mission paths into generic components

---

# Autoloads

Keep singletons limited.

Potential Autoloads:
- `GameManager`
- `AudioManager`
- `SaveManager`
- `LocalizationManager`

Faction state may live in `GameManager`, but faction definitions should remain Resource-driven.

---

# Version 0.1 Vertical Slice

Do **not** build the entire war or a complete campaign first.

Build one small polished mission that establishes the core visual and gameplay identity of the project. The first level begins outdoors in a dense German forest and progressively moves through fortified positions into a bunker/command-post interior.

## First Level — Forest Command Post

### Setting
A fictional but historically plausible German military command-post complex in a dense Central European forest during World War II. The map should feel geographically believable rather than like a sequence of disconnected combat arenas.

The level should transition naturally through three major visual spaces:

1. **Dense forest approach**
2. **Fortified bunker perimeter**
3. **Interior command post / bunker complex**

The exterior should establish scale, atmosphere and tension; the bunker approach should tighten the combat space; the command-post interior should become more claustrophobic, detailed and information-rich.

### Area 1 — Dense German Forest

The player starts outdoors beneath a dense tree canopy. The opening should immediately communicate that this is a modern photorealistic WWII FPS rather than a retro shooter.

Environment features:
- Tall spruce, fir and pine trees appropriate to Central Europe
- Dense undergrowth, ferns, moss, roots and fallen branches
- Uneven ground with mud, rocks, leaves and shallow drainage depressions
- Narrow dirt road or military track leading toward the installation
- Morning mist or low forest fog
- Volumetric light shafts through the canopy where performance permits
- Wet foliage and subtle wind movement
- Distant artillery and aircraft ambience
- Camouflaged military signage and telephone wire
- Occasional abandoned crates, equipment and defensive positions
- Natural terrain used as cover rather than waist-high game-design barriers

Avoid making the forest an enormous open world. It should be visually dense but designed around a controlled mission corridor with optional side routes and believable sight lines.

### Area 2 — Bunker / Defensive Perimeter

The forest gradually reveals a fortified German position rather than cutting abruptly to a bunker scene.

Possible features:
- Camouflaged concrete bunker entrances
- Trenches and foxholes
- Sandbag fighting positions
- Barbed wire
- Timber revetments
- Generator or utility shed
- Radio/telephone lines
- Guard checkpoint
- Searchlight or observation position
- One fixed machine-gun emplacement
- Ammunition and supply crates
- Concealed secondary entrance

For an Allied mission, the mounted weapon at the defensive position can be an enemy-operated **MG42** that becomes usable after the position is cleared. For a German-side version or later mirrored scenario, faction configuration determines appropriate friendly/enemy use.

### Area 3 — Interior Command Post

The final portion takes place inside a functional German command post integrated into or directly behind the bunker complex.

The interior should be noticeably richer in props and environmental storytelling than the exterior.

Rooms can include:
- Entrance security corridor
- Guard room
- Communications/radio room
- Operations/map room
- Officer office
- Records/document room
- Equipment storage
- Ammunition storage
- Generator/mechanical room
- Narrow connecting corridors
- Emergency or rear exit

Command-post dressing should include historically plausible:
- Large wall maps
- Unit markers
- Field telephones
- Radios
- Headsets
- Typewriters
- Desks and chairs
- Filing cabinets
- Message forms and paperwork
- Clocks
- Lamps
- Coat hooks and personal equipment
- Weapon racks
- Electrical conduit and exposed pipes
- Directional signs and room labels
- Period military insignia/signage where appropriate to historical context

Interior audio should differ clearly from the forest:
- Reverberant gunfire
- Muffled exterior explosions
- Radio chatter
- Telephone ringing
- Electrical hum
- Ventilation/generator noise
- Footsteps changing by concrete, wood and metal surfaces

### Suggested Mission Flow

```text
FOREST START
     ↓
Recon / patrol encounter
     ↓
Dirt road and concealed defenses
     ↓
Bunker perimeter firefight
     ↓
Optional side entrance / trench route
     ↓
Enter command post
     ↓
Clear communications and operations rooms
     ↓
Complete primary objective
     ↓
Reach rear exit / extraction point
```

A suitable first objective is to **capture, destroy or retrieve information from the command post**. Keep the exact story flexible until the campaign narrative is finalized.

### Recommended v0.1 Perspective
For the very first playable build, implement this mission from the **Allied perspective**: the player advances through the German forest defenses, clears the bunker perimeter, and enters the command post. Keep all faction systems data-driven so a German-side mission can be added later without duplicating gameplay code. Do not attempt to make the same first map fully playable from both sides until the Allied vertical slice is stable.

### Vertical-Slice Requirements

Include:
- 6–9 distinct combat spaces
- At least two substantial outdoor forest encounters
- One fortified bunker/perimeter encounter
- Multiple bunker/command-post interior rooms
- One fixed machine-gun emplacement
- One primary mission objective
- One optional secondary objective or hidden route
- At least one alternate route into or through the bunker complex
- Exterior-to-interior lighting transition
- Exterior-to-interior audio transition
- One checkpoint before the main bunker interior
- Environmental storytelling in the command post

## Player
- Move
- Mouse look
- Sprint
- Crouch
- Aim down sights
- Fire
- Reload
- Throw grenade
- Use/interact
- Take damage
- Die/restart

## Allied Test Loadout
- Knife
- M1911 pistol
- Thompson SMG
- Mk 2 grenade
- Bazooka
- Access to fixed M1919 .30 cal emplacement where placed

## German Test Loadout
- Knife
- P38 pistol
- MP40 SMG
- MP44 / StG 44
- Stielhandgranate
- Panzerfaust
- Access to fixed MG42 emplacement where placed

Not every weapon needs to be carried simultaneously. Mission loadouts should determine availability.

## AI
One shared soldier AI framework with:
- Allied soldier configuration
- German soldier configuration
- Idle
- Patrol
- Detect enemy
- Engage
- Search
- Death

## Language
- Allied soldiers speak English
- German soldiers speak German
- Subtitles supported independently

## Presentation
- **Bastion Front** title branding established
- Gritty, desaturated cinematic WWII art direction
- Modern PBR materials
- High-resolution environment assets
- Realistic weapon models
- Modern lighting
- Muzzle flash
- Shell ejection
- Bullet impact decals
- Smoke/dust
- Basic blood effects
- Character animation
- Ambient battlefield audio

When this vertical slice is fun and stable, expand it.

---

# Development Milestones

## Milestone 1 — Movement Sandbox
- First-person player
- Test room
- Mouse look
- Movement
- Sprint/crouch
- Interaction raycast

## Milestone 2 — Weapon Prototype
- Pistol
- SMG
- ADS
- Hitscan shooting
- Reloading
- Recoil
- Impacts

## Milestone 3 — Faction Framework
- `FactionData`
- Allied configuration
- German configuration
- Faction-aware loadouts
- Friend/foe relationships

## Milestone 4 — Basic AI
- Shared soldier AI
- Navigation
- Vision/hearing
- Faction targeting
- Death

## Milestone 5 — Explosives
- Allied grenade
- German stick grenade
- Bazooka
- Panzerfaust
- Explosion damage/effects

## Milestone 6 — Mounted Machine Guns
- M1919 emplacement
- MG42 emplacement
- Mount/dismount
- Limited firing arcs
- AI-compatible interface later

## Milestone 7 — Bastion Front WWII Art Pass
- Modular European environment
- Allied character model
- German character model
- Accurate uniforms/equipment
- Modern weapon viewmodels
- PBR materials
- Title-screen background scene or in-engine cinematic tableau
- **BASTION FRONT** main-menu treatment
- Gritty WWII color grading and weathered-material pass

## Milestone 8 — Audio / Dialogue
- Weapon audio
- German voice set
- Allied voice set
- Subtitles
- Ambient battlefield audio

## Milestone 9 — First Complete Mission
- Dense German forest opening
- Fortified bunker perimeter
- Interior command post
- Briefing
- Objectives
- Combat progression
- Exterior/interior lighting and audio transitions
- End condition
- Restart/checkpoint

## Milestone 10 — Opposite-Faction Mission
Reuse the same framework to build a mission playable from the other side without duplicating core gameplay systems.

---

# Vibe-Coding Rules

When an AI coding agent works on this repository:

1. Treat this file as the authoritative design/architecture specification.
2. Implement only the current milestone unless specifically instructed otherwise.
3. Keep the project runnable after every meaningful change.
4. Prefer small, modular scripts over large generated systems.
5. Use typed GDScript.
6. Do not rewrite working systems unnecessarily.
7. Do not introduce plugins/dependencies without documenting why they are needed.
8. Keep faction differences data-driven.
9. Never bake Allied/German weapon assumptions into generic weapon code.
10. Never duplicate the entire AI system per faction.
11. Use placeholder assets until gameplay works.
12. Replace placeholders incrementally with production-quality GLB/glTF assets.
13. Optimize only after profiling demonstrates a problem.
14. Maintain a short `CHANGELOG.md` after each milestone.
15. Add comments explaining *why* non-obvious code exists, not narrating obvious syntax.
16. Do not automatically expand scope into vehicles, multiplayer, complex inventory, open-world systems, or advanced squad command systems.
17. Historical data belongs in Resources/configuration files where possible, not scattered throughout code.
18. Dialogue text and subtitles must remain separable from voice audio for localization.
19. German combat dialogue should be authored or reviewed by fluent/native German speakers before final production.
20. Original maps, missions and characters should be used rather than copying protected level layouts or assets from existing games.

---

# Initial AI Coding Prompt

Use the following when starting the repository with a coding model:

```text
Use this Markdown file as the authoritative specification for the project.

Create **Bastion Front** as a Godot 4.7.x Forward+ Windows FPS project using typed GDScript.

Begin ONLY with Milestone 1: Movement Sandbox.

Create a clean directory structure matching this specification and implement:
- CharacterBody3D first-person player
- WASD movement
- mouse look
- sprint
- crouch
- gravity
- interaction RayCast3D
- a simple greybox test room

Do not implement weapons, AI, final art assets, campaigns or other later milestones yet.

Keep scripts modular, typed and documented. Verify that all scene/script paths are internally consistent and that the project can launch directly into the test room.

After completing Milestone 1, stop and summarize the created files and any Godot editor steps that still require manual action.
```

---

# Long-Term Direction

**Bastion Front** can eventually expand into a collection of original Allied and German WWII missions across Europe while keeping the underlying codebase compact.

The core philosophy is:

```text
Historically grounded WWII setting
            +
modern photorealistic presentation
            +
straightforward FPS mechanics
            +
faction-authentic equipment/dialogue
            +
small modular Godot systems
            =
manageable modern WWII FPS
```

The first priority is always a **small, playable, polished vertical slice** before adding content breadth.
