extends Node
@export var player: CharacterBody3D
var _distance: float = 0.0


func _physics_process(delta: float) -> void:
	if not get_node("/root/CombatAudio").can_emit(player): return
	if player.is_on_floor():
		_distance += Vector2(player.velocity.x, player.velocity.z).length() * delta
		if _distance >= 1.8:
			_distance = 0.0
			var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(player.global_position + Vector3.UP * 0.2, player.global_position - Vector3.UP * 0.4, 1)
			var hit: Dictionary = player.get_world_3d().direct_space_state.intersect_ray(query)
			var surface: StringName = &"dirt"
			if not hit.is_empty():
				surface = hit["collider"].get_meta(&"surface", &"dirt")
			if get_node("/root/CombatAudio").interior_bounds.has_point(player.global_position):
				surface = &"concrete"
			get_node("/root/CombatAudio").play(StringName("footstep_" + str(surface)), player.global_position, player)
