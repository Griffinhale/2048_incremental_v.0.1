extends Node


signal generator_updated(id: String, new_yield: float)

var generators := []
var timers := {}

@onready var upgrade_manager := get_node_or_null("/root/UpgradeManager")

func _ready():
	load_generators()
	start_all_generators()

func load_generators():
	# In a real setup this would come from a JSON file.
	# Add fields for if generator is active, level up cost, and cost growth
	# For now, define directly:
	generators = [
	{
		"id": "gen_0", "label": "Basic Combiner",
		"tile_targets": [0, 1], "level": 0, "base_yield": 0.2,
		"growth_curve": "linear", "growth_factor": 1.0,
		"interval_seconds": 1.0, "multiplier": 1.0,
		"level_cost": 1.0, "cost_growth": 1.12,
		"active": false
	},
	{
		"id": "gen_1", "label": "Twin Amplifier",
		"tile_targets": [2, 3], "level": 0, "base_yield": 1.0,
		"growth_curve": "exponential", "growth_factor": 1.1,
		"interval_seconds": 2.0, "multiplier": 1.0,
		"level_cost": 2.0, "cost_growth": 1.15,
		"active": false
	},
	{
		"id": "gen_2", "label": "Prime Reactor",
		"tile_targets": [5, 7], "level": 0, "base_yield": 0.8,
		"growth_curve": "exponential", "growth_factor": 1.15,
		"interval_seconds": 3.0, "multiplier": 1.0,
		"level_cost": 3.5, "cost_growth": 1.18,
		"active": false
	},
	{
		"id": "gen_3", "label": "Echo Producer",
		"tile_targets": [9, 6], "level": 0, "base_yield": 1.5,
		"growth_curve": "linear", "growth_factor": 1.5,
		"interval_seconds": 4.0, "multiplier": 1.0,
		"level_cost": 5.0, "cost_growth": 1.2,
		"active": false
	},
	{
		"id": "gen_4", "label": "Recursive Synth",
		"tile_targets": [10, 4], "level": 0, "base_yield": 2.0,
		"growth_curve": "exponential", "growth_factor": 1.25,
		"interval_seconds": 6.0, "multiplier": 1.0,
		"level_cost": 7.5, "cost_growth": 1.22,
		"active": false
	},
	{
		"id": "gen_5", "label": "Singularity Driver",
		"tile_targets": [8, 11], "level": 0, "base_yield": 3.5,
		"growth_curve": "linear", "growth_factor": 2.0,
		"interval_seconds": 10.0, "multiplier": 1.0,
		"level_cost": 10.0, "cost_growth": 1.25,
		"active": false
	}
]


func start_all_generators():
	for gen_data in generators:
		var interval = gen_data["interval_seconds"]
		var timer = Timer.new()
		timer.wait_time = interval
		timer.autostart = true
		timer.one_shot = false
		timer.timeout.connect(_on_generator_tick.bind(gen_data["id"]))
		add_child(timer)
		timers[gen_data["id"]] = timer
		
func is_generator_unlocked(gen: Dictionary) -> bool:
	if gen.get("active", false):
		return true

	for tile in gen.get("tile_targets", []):
		if not StatsTracker.has_seen_tile(tile):
			return false

	gen["active"] = true  # Activate permanently for this prestige
	return true

func _on_generator_tick(generator_id: String):
	var gen = get_generator_by_id(generator_id)
	if not gen:
		return
	
	if not is_generator_unlocked(gen):
		return
		
	var yield_curr = calculate_yield(gen)
	CurrencyManager.add_currency(yield_curr)
	emit_signal("generator_updated", generator_id, yield_curr)

func calculate_yield(gen: Dictionary) -> float:
	var level = gen["level"]
	var base = gen["base_yield"]
	var growth = gen["growth_factor"]
	var mult = gen.get("multiplier", 1.0)
	var tile_gap = abs(gen["tile_targets"][0] - gen["tile_targets"][1])
	var spread_bonus = 1.0 + (tile_gap / 10.0)  # Tunable formula

	match gen["growth_curve"]:
		"exponential":
			base *= pow(growth, level)
		"linear":
			base *= level

	#if upgrade_manager:
	#	mult *= upgrade_manager.get_generator_multiplier(gen["id"])

	var curr_yield = base * mult * spread_bonus
	return curr_yield

func get_generator_by_id(id: String) -> Dictionary:
	for g in generators:
		if g["id"] == id:
			return g
	return {}

func level_up_generator(id: String):
	var gen = get_generator_by_id(id)
	if gen:
		var cost = gen.get("level_cost", 1.0)
		if CurrencyManager.spend_currency(cost):
			gen["level"] += 1
			gen["level_cost"] *= gen.get("cost_growth", 1.15)
			if gen["level"] == 1:
				gen["active"] = true
		else:
			print("Not enough currency to level up %s (cost: %.2f)" % [id, cost])
			
func is_generator_active(id: String) -> bool:
	var gen = get_generator_by_id(id)
	return gen.get("active", false)

func refresh_generator_activation():
	for gen in generators:
		if gen.get("active", false):
			continue

		var unlocked = true
		for tile in gen.get("tile_targets", []):
			if not StatsTracker.has_seen_tile(tile):
				unlocked = false
				break

		if unlocked:
			gen["active"] = true
