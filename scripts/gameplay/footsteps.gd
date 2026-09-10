extends Node
@export var player: CharacterBody3D
var _distance: float = 0.0


func _physics_process(delta: float) -> void:
	if player.is_on_floor():
		_distance += Vector2(player.velocity.x, player.velocity.z).length() * delta
		if _distance >= 1.8:
			_distance = 0.0
			get_node("/root/CombatAudio").play(&"footstep", player.global_position, player)
