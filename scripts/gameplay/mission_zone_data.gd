class_name MissionZoneData
extends Resource
## An authored zone, not a procedural map generator. Every option is validated offline.
@export var zone_id: StringName
@export var bounds: AABB
@export var options: Array[MissionZoneOption] = []
