extends CanvasLayer

@export var player: CharacterBody3D
@export var health: HealthComponent
@onready var label: Label = $Health


func _ready() -> void:
	health.health_changed.connect(_update_health)
	health.died.connect(_on_death)
	_update_health(health.current_health, health.max_health)


func _unhandled_input(event: InputEvent) -> void:
	if health.current_health <= 0.0 and event.is_action_pressed("restart"):
		get_tree().reload_current_scene()


func _update_health(current: float, _maximum: float) -> void:
	label.text = "HEALTH  %d" % ceili(current)


func _on_death() -> void:
	label.text = "YOU DIED  —  Enter to restart"
	player.set_physics_process(false)
	player.velocity = Vector3.ZERO
	player.get_node("MouseLook").set_process_unhandled_input(false)
	player.get_node("Head/Camera3D/WeaponRig").process_mode = Node.PROCESS_MODE_DISABLED
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
