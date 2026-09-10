extends StaticBody3D
signal activated(action: StringName, player: CharacterBody3D)
@export var action: StringName
@export var prompt: String = "E: interact"


func get_prompt() -> String:
	return prompt


func interact(player: CharacterBody3D) -> void:
	activated.emit(action, player)
