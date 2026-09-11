extends Node
var player: CharacterBody3D
var camera: Camera3D
var pressure: float = 0.0
var side: float = 0.0
var _cooldown: float = 0.0

func _ready() -> void:
	player = get_parent() as CharacterBody3D
	camera = player.get_node("Head/Camera3D")
	get_node("/root/CombatAudio").bullet_passed.connect(_bullet)

func _bullet(start: Vector3, end: Vector3, source: CollisionObject3D) -> void:
	if player.get_node("HealthComponent").current_health <= 0: return
	if source == player or not FactionData.hostile(player, source) or _cooldown > 0: return
	var closest: Vector3 = Geometry3D.get_closest_point_to_segment(camera.global_position, start, end)
	if closest.distance_to(camera.global_position) > 1.6: return
	pressure = 1.0
	side = signf(camera.global_basis.x.dot(start - camera.global_position))
	_cooldown = 0.4
	get_node("/root/CombatAudio").play(&"impact_metal", closest)

func _process(delta: float) -> void:
	if player.get_node("HealthComponent").current_health <= 0: return
	pressure = maxf(0, pressure - delta * 2.5)
	_cooldown -= delta
	var reduced: bool = get_node("/root/PlayerSettings").values.reduced_motion
	camera.rotation.z = side * pressure * 0.004 if not reduced else 0.0
