class_name AscensionManager
extends Node

static var instance: AscensionManager

func _ready():
	instance = self

static func get_current_ascension_bonuses() -> Dictionary:
	if not instance:
		return {}
	return {}  # Stub - return empty for now

static func has_custom_board_config() -> bool:
	return false  # Stub

static func get_board_config() -> Dictionary:
	return {"size": 16, "max_tile": 15}  # Default 4x4 board
