extends Node
## A shallow combat crouch keeps the shared collision and vision height with the rig.
var actor: InfantryBrain
var capsule: CapsuleShape3D
var height: float = 1.8

func _ready() -> void:
	actor = get_parent()
	capsule = actor.get_node("BodyCollision").shape.duplicate()
	actor.get_node("BodyCollision").shape = capsule

func _physics_process(delta: float) -> void:
	if not get_node("/root/CombatAudio").can_emit(actor): return
	height = move_toward(height, 1.58 if actor.crouching else 1.8, delta * 0.88)
	capsule.height = height
	actor.get_node("BodyCollision").position.y = height * 0.5
	actor.get_node("Eyes").position.y = height - 0.3
