class_name MissionZoneOption
extends Resource
@export var label: String
@export var actor_positions: Dictionary[StringName, Vector3] = {}
@export var patrol_routes: Dictionary[StringName, PackedVector3Array] = {}
@export var supply_positions: Dictionary[StringName, Vector3] = {}
@export var dressing_anchors: PackedVector3Array = []
@export var restricted_flank: bool = false
