class_name FactionData
extends Resource

@export var faction_id: StringName
@export var display_name: String
@export var spoken_language: StringName
@export var weapons: Array[WeaponData] = []
@export var grenade: WeaponData
@export var hostile_ids: Array[StringName] = []
@export var uniform_scene: PackedScene
@export var voice_set: Resource
@export var sleeve_color: Color = Color(0.38, 0.36, 0.25)
@export var visual_variants: Array[PackedScene] = []


static func hostile(first: Object, second: Object) -> bool:
	if not is_instance_valid(first) or not is_instance_valid(second):
		return true
	if not first.has_meta(&"faction") or not second.has_meta(&"faction"):
		return true
	var a: FactionData = first.get_meta(&"faction") as FactionData
	var b: FactionData = second.get_meta(&"faction") as FactionData
	return b.faction_id in a.hostile_ids
