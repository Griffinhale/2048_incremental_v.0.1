class_name ChallengeManager
extends Node

static var instance: ChallengeManager

func _ready():
	instance = self

static func get_active_challenges() -> Array:
	if not instance:
		return []
	return []  # Stub - return empty for now

static func get_completed_challenges() -> Array:
	if not instance:
		return []
	return []  # Stub - return empty for now
