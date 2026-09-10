extends Node

@export var player: CharacterBody3D
@export var head: Node3D
@export_range(0.01, 1.0) var sensitivity_degrees: float = 0.1

const PITCH_LIMIT: float = deg_to_rad(85.0)


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("release_mouse"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("capture_mouse") and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var motion: InputEventMouseMotion = event as InputEventMouseMotion
		var sensitivity: float = deg_to_rad(sensitivity_degrees)
		player.rotate_y(-motion.screen_relative.x * sensitivity)
		head.rotation.x = clampf(head.rotation.x - motion.screen_relative.y * sensitivity, -PITCH_LIMIT, PITCH_LIMIT)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
