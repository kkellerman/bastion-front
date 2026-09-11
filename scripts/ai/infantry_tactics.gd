extends Node
## Optional encounter layer; observed points never track hidden targets.
var actor: InfantryBrain
var order: StringName = &"investigate"
var destination: Vector3
var _decision: float = 0.0
var _broadcast: float = 0.0
var _search_time: float = 0.0
var _search_index: int = 0
var _cover: Node3D
var role: int = 0

func _ready() -> void:
	actor = get_parent() as InfantryBrain
	actor.add_to_group(&"tactical_infantry")

func tick(delta: float) -> bool:
	actor.crouching = order == &"cover" and actor.sees_target and actor.global_position.distance_to(destination) < 0.9
	_broadcast -= delta
	_decision -= delta
	if actor.sees_target and _broadcast <= 0:
		_broadcast = 2.5
		for other: InfantryBrain in get_tree().get_nodes_in_group(&"tactical_infantry"):
			if other != actor and not FactionData.hostile(actor, other) and actor.global_position.distance_to(other.global_position) < 18:
				other.receive_alert(actor.last_known_position)
	if actor.state not in [InfantryBrain.State.CHASE, InfantryBrain.State.ATTACK]: return false
	if actor.motor.move_speed <= 0: return false
	if actor.sees_target:
		_search_time = 0
		if _decision <= 0:
			_decision = 2.0
			_choose_cover()
			order = &"advance" if role % 2 == 1 else &"suppress"
			if _cover != null: order = &"cover"
			elif role % 2 == 1 and _supporting_ally():
				order = &"flank"
				var toward: Vector3 = (actor.last_known_position - actor.global_position).normalized()
				var side: Vector3 = Vector3(-toward.z, 0, toward.x) * (1 if role % 4 == 1 else -1)
				destination = NavigationServer3D.map_get_closest_point(actor.get_world_3d().navigation_map, actor.global_position + toward * 3 + side * 4)
		if order in [&"cover", &"flank"] and actor.global_position.distance_to(destination) > 0.9:
			actor._set_state(InfantryBrain.State.CHASE)
			actor.motor.travel(destination, delta)
			return true
		return false
	if actor._memory_remaining > 0:
		order = &"investigate"
		return false
	order = &"search"
	_search_time += delta
	if _search_time > 5.0:
		actor._set_state(InfantryBrain.State.IDLE)
		_search_time = 0
		return true
	if _decision <= 0:
		_decision = 1.5
		_search_index += 1
		var angle: float = float((_search_index + role) % 4) * PI * 0.5
		destination = actor.last_known_position + Vector3(cos(angle) * 2.5, 0, sin(angle) * 2.5)
	actor.motor.travel(destination, delta)
	return true

func _choose_cover() -> void:
	_cover = null
	var best: float = 14.0
	for marker: Node3D in get_tree().get_nodes_in_group(&"infantry_cover"):
		var distance: float = actor.global_position.distance_to(marker.global_position)
		if distance >= best or marker.global_position.distance_to(actor.last_known_position) < 5: continue
		var occupied: bool = false
		for other: InfantryBrain in get_tree().get_nodes_in_group(&"tactical_infantry"):
			if other != actor and other.state != InfantryBrain.State.DEATH and other.global_position.distance_to(marker.global_position) < 1.5: occupied = true
		if occupied: continue
		var space: PhysicsDirectSpaceState3D = actor.get_world_3d().direct_space_state
		var blocked: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(marker.global_position + Vector3.UP * 0.65, actor.last_known_position + Vector3.UP, 1))
		if blocked.is_empty(): continue
		best = distance
		_cover = marker
		destination = marker.global_position

func _supporting_ally() -> bool:
	for other: InfantryBrain in get_tree().get_nodes_in_group(&"tactical_infantry"):
		if other != actor and not FactionData.hostile(actor, other) and other.sees_target and other.state == InfantryBrain.State.ATTACK and other.global_position.distance_to(actor.global_position) < 16: return true
	return false
