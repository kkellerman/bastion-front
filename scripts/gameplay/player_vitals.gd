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
	var rig: Node3D = player.get_node("Head/Camera3D/WeaponRig") as Node3D
	if rig.mounted != null:
		rig.mounted.dismount()
	label.text = "YOU DIED  —  Enter to restart"
	player.set_physics_process(false)
	player.velocity = Vector3.ZERO
	player.get_node("MouseLook").set_process_unhandled_input(false)
	player.get_node("Head/Camera3D/WeaponRig").process_mode = Node.PROCESS_MODE_DISABLED
	rig._clear_input()
	rig.viewmodel.hide()
	rig.viewmodel.muzzle_effect.stop()
	var camera: Camera3D = player.get_node("Head/Camera3D")
	var reduced: bool = get_node("/root/PlayerSettings").values.reduced_motion
	var head: Node3D = player.get_node("Head")
	# Move the head rather than the body: collider and checkpoint position stay stable.
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(head, "position:y", 0.28, 0.35 if reduced else 0.85).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(head, "rotation:x", -0.12 if reduced else -0.35, 0.65)
	tween.tween_property(camera, "rotation:z", 0.0 if reduced else 0.16, 0.7)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
