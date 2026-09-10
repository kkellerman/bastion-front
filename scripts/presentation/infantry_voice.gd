extends Node3D
## Text and recordings stay separate. Empty recording slots never synthesize speech.
signal subtitle_requested(text: String)
@export var voice_set: InfantryVoiceSet
var _cooldown: float = 0.0
var _had_contact: bool = false
var director: Node
var _categories: Dictionary[StringName, float] = {}
var _scan: float = 0.0
var _dead: bool = false
var _previous_sight: bool = false
var _pending: StringName = &""
var _pending_lifetime: float = 0.0

func _process(delta: float) -> void:
	_cooldown = maxf(0, _cooldown - delta)
	_pending_lifetime -= delta
	if _pending != &"":
		if _pending_lifetime <= 0 or _dead: _pending = &""
		elif say(_pending): _pending = &""
	for key: StringName in _categories: _categories[key] = maxf(0, _categories[key] - delta)
	_scan -= delta
	if _scan > 0 or _dead: return
	_scan = 0.5
	var actor: InfantryBrain = get_parent() as InfantryBrain
	if actor != null:
		if _previous_sight and not actor.sees_target: say(&"lost_sight")
		_previous_sight = actor.sees_target
	for grenade: Node3D in get_tree().get_nodes_in_group(&"explosive_projectiles"):
		if global_position.distance_to(grenade.global_position) < 9: say(&"grenade_warning")

func say(category: StringName) -> bool:
	if director == null or _cooldown > 0 or _categories.get(category, 0.0) > 0: return false
	if not director.request(self, category): return false
	_cooldown = 5.0
	_categories[category] = 16.0
	subtitle_requested.emit(voice_set.subtitles[category])
	return true

func queue_line(category: StringName) -> void:
	_pending = category
	_pending_lifetime = 8.0

func state_changed(state: String) -> void:
	match state:
		"ALERT":
			if get_parent().sees_target:
				_had_contact = true
				say(&"spotting")
		"HURT": say(&"taking_fire")
		"DEATH":
			say(&"death")
			_dead = true
		"CHASE": say(&"moving")
		"IDLE":
			if _had_contact:
				say(&"lost_sight")
				_had_contact = false
