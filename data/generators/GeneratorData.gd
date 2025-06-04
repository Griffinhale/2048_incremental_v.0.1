# res://data/generator_data.gd
class_name GeneratorData
extends Resource

@export var id: String
@export var label: String
@export var tile_targets: Array
@export var level: int = 0
@export var base_yield: float
@export var growth_curve: String
@export var growth_factor: float
@export var interval_seconds: float
@export var multiplier: float = 1.0
@export var level_cost: float
@export var cost_growth: float
@export var active: bool = false
@export var previously_unlocked: bool
@export var newly_unlocked: bool
@export var unlock_requirements: Array

# Constructor for easy creation
func _init(
	p_id: String = "",
	p_label: String = "",
	p_tile_targets: Array[int] = [],
	p_base_yield: float = 1.0,
	p_growth_curve: String = "linear",
	p_growth_factor: float = 1.0,
	p_interval_seconds: float = 1.0,
	p_level_cost: float = 1.0,
	p_cost_growth: float = 1.15
):
	id = p_id
	label = p_label
	tile_targets = p_tile_targets
	base_yield = p_base_yield
	growth_curve = p_growth_curve
	growth_factor = p_growth_factor
	interval_seconds = p_interval_seconds
	level_cost = p_level_cost
	cost_growth = p_cost_growth
	unlock_requirements = p_tile_targets

# Helper methods
func get_spread_bonus() -> float:
	if tile_targets.size() < 2:
		return 1.0
	var tile_gap = abs(tile_targets[0] - tile_targets[1])
	return 1.0 + (tile_gap / 10.0)

func calculate_level_yield() -> float:
	match growth_curve:
		"exponential":
			return base_yield * pow(growth_factor, level)
		"linear":
			return base_yield + (base_yield * growth_factor * level)
		_:
			return base_yield

func is_empty():
	pass
