# res://scripts/managers/lore_manager.gd
class_name LoreManager
extends Node

static var instance: LoreManager

func _ready():
	instance = self

static func get_unlocked_insights() -> Dictionary:
	if not instance:
		return {}
	return {}  # Stub - return empty for now
