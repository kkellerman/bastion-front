class_name WeaponData
extends Resource
@export var handling: WeaponHandlingData = preload("res://resources/weapons/handling/pistol.tres")
@export var support_hand_position: Vector3 = Vector3(-0.035, -0.085, 0.07)
## Shared configuration only. Magazine, reserve and timers belong to WeaponBase.

enum ShotType { HITSCAN, PROJECTILE }

@export var weapon_id: StringName
@export var display_name: String = "Weapon"
@export var faction: StringName
@export var weapon_class: StringName
@export_range(0.1, 1000.0) var damage: float = 25.0
## Rounds per minute, regardless of trigger mode.
@export_range(1.0, 2000.0) var rate_of_fire: float = 300.0
@export var automatic: bool = false
@export_range(1, 200) var magazine_capacity: int = 7
@export var reserve_ammo_type: StringName
@export_range(0, 1000) var starting_reserve: int = 35
@export_range(0.1, 10.0) var reload_time: float = 1.8
@export_range(0.0, 20.0) var recoil: float = 3.0
@export_range(0.0, 10.0) var spread: float = 0.35
@export_range(1.0, 1000.0) var effective_range: float = 80.0
@export var hitscan_or_projectile: ShotType = ShotType.HITSCAN
@export var projectile_scene: PackedScene
@export var viewmodel_scene: PackedScene
@export var world_model_scene: PackedScene
@export var muzzle_audio: AudioStream
@export var muzzle_flash_size: Vector2 = Vector2(0.09, 0.13)
@export var reload_audio: AudioStream
@export var dry_audio: AudioStream
@export var projectile_speed: float = 30.0
@export var projectile_gravity: float = 0.0
@export var fuse_time: float = 8.0
@export var explode_on_contact: bool = true
@export var blast_radius: float = 5.0
