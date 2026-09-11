extends Node
const P = preload("res://scripts/presentation/dressing_parts.gd")

func _ready() -> void:
	var mission: Node3D = get_parent()
	mission.player.add_child(load("res://scripts/presentation/suppression_feedback.gd").new())
	var role: int = 0
	for enemy: InfantryBrain in mission.get_node("Enemies").get_children():
		var tactics: Node = load("res://scripts/ai/infantry_tactics.gd").new()
		tactics.role = role
		enemy.add_child(tactics)
		enemy.tactics = tactics
		role += 1
	# Existing revetments/sandbags supply real cover; markers add no hidden collision.
	for point: Vector3 in [Vector3(-5.4, 0, -46), Vector3(2.6, 0, -48), Vector3(-5, 0, -56), Vector3(5, 0, -56), Vector3(-3, 0, -64), Vector3(3, 0, -73)]:
		var marker: Marker3D = Marker3D.new()
		mission.add_child(marker)
		marker.position = point
		marker.add_to_group(&"infantry_cover")
	for kind: String in ["ammo", "health"]:
		var supply: Node3D = load("res://scenes/pickups/" + kind + ".tscn").instantiate()
		mission.get_node("Supplies").add_child(supply)
		supply.position = Vector3(13, 0, -31 if kind == "ammo" else -33)
	# East drainage track bypasses the central MG arc and rejoins at the entrance.
	for z: int in range(-16, -55, -3):
		P.box(mission, Vector3(12 + sin(z * 0.17), 0.008, z), Vector3(1.6, 0.014, 2.9), P.material(Color(0.12, 0.105, 0.073)))
	var sign: Node3D = Node3D.new()
	mission.add_child(sign)
	sign.position = Vector3(5, 0, -16)
	P.box(sign, Vector3(0, 0.7, 0), Vector3(0.065, 1.4, 0.065), load("res://assets/materials/presentation/bark.tres"))
	P.sign_text(sign, Vector3(0, 1.2, 0), "VERSORGUNG  →", 0.002)
