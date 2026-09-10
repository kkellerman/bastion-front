class_name InfantryVoiceSet
extends Resource
@export var language: StringName = &"de"
@export var subtitles: Dictionary[StringName, String] = {}
@export var recordings: Dictionary[StringName, AudioStream] = {}
@export var subtitle_keys: Dictionary[StringName, StringName] = {}
@export var durations: Dictionary[StringName, float] = {}
