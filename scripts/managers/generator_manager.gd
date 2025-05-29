extends Node


signal generator_updated(id: String, new_yield: float)
signal generator_unlocked(id: String)

var generators := []
var timers := {}
var yield_algorithms := {}
var generator_upgrades := {}

var debug_data := {
	"total_yields": {},
	"tick_counts": {},
	"algorithm_seeds": {},
	"last_yields": {},
	"active_generators": 0,
	"total_lifetime_yield": 0.0
}

func _ready():
	initialize_yield_algorithms()
	load_generators()
	#load_generator_upgrades()
	start_all_generators()

func initialize_yield_algorithms():
	pass

func load_generators():
	# In a real setup this would come from a JSON file.
	# Add fields for if generator is active, level up cost, and cost growth
	# For now, define directly:
	generators = [
		{
			"id": "gen_0", "label": "Basic Combiner",
			"tile_targets": [0, 1], "level": 1, "base_yield": 0.2,
			"growth_curve": "linear", "growth_factor": 1.0,
			"interval_seconds": 1.0, "multiplier": 1.0,
			"level_cost": 1.0, "cost_growth": 1.12,
			"active": true
		},
		{
			"id": "gen_1", "label": "Twin Amplifier",
			"tile_targets": [2, 3], "level": 0, "base_yield": 1.0,
			"growth_curve": "exponential", "growth_factor": 1.1,
			"interval_seconds": 2.0, "multiplier": 1.0,
			"level_cost": 2.0, "cost_growth": 1.15,
			"active": true
		},
		{
			"id": "gen_2", "label": "Prime Reactor",
			"tile_targets": [5, 7], "level": 0, "base_yield": 0.8,
			"growth_curve": "exponential", "growth_factor": 1.15,
			"interval_seconds": 3.0, "multiplier": 1.0,
			"level_cost": 3.5, "cost_growth": 1.18,
			"active": true
		},
		{
			"id": "gen_3", "label": "Echo Producer",
			"tile_targets": [9, 6], "level": 0, "base_yield": 1.5,
			"growth_curve": "linear", "growth_factor": 1.5,
			"interval_seconds": 4.0, "multiplier": 1.0,
			"level_cost": 5.0, "cost_growth": 1.2,
			"active": true
		},
		{
			"id": "gen_4", "label": "Recursive Synth",
			"tile_targets": [10, 4], "level": 0, "base_yield": 2.0,
			"growth_curve": "exponential", "growth_factor": 1.25,
			"interval_seconds": 6.0, "multiplier": 1.0,
			"level_cost": 7.5, "cost_growth": 1.22,
			"active": true
		},
		{
			"id": "gen_5", "label": "Singularity Driver",
			"tile_targets": [8, 11], "level": 0, "base_yield": 3.5,
			"growth_curve": "linear", "growth_factor": 2.0,
			"interval_seconds": 10.0, "multiplier": 1.0,
			"level_cost": 10.0, "cost_growth": 1.25,
			"active": true
		}
	]
	
	# Initialize debug tracking
	for gen in generators:
		debug_data.total_yields[gen.id] = 0.0
		debug_data.tick_counts[gen.id] = 0
		debug_data.last_yields[gen.id] = 0.0

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

	# Check if all required tiles have been seen
	for tile in gen.get("tile_targets", []):
		if not StatsTracker.has_seen_tile(tile):
			return false

	# Unlock the generator
	gen["active"] = true
	debug_data.active_generators += 1
	emit_signal("generator_unlocked", gen.id)
	print("Generator unlocked: ", gen.label)
	return true

func _on_generator_tick(generator_id: String):
	var gen = get_generator_by_id(generator_id)
	if not gen:
		return
	
	if not is_generator_unlocked(gen):
		return
	
	# Only generate if generator has been leveled up at least once
	if gen.level <= 0:
		return
		
	var yield_curr = calculate_yield(gen)
	
	# Update debug data
	debug_data.total_yields[generator_id] += yield_curr
	debug_data.tick_counts[generator_id] += 1
	debug_data.last_yields[generator_id] = yield_curr
	debug_data.total_lifetime_yield += yield_curr
	
	# Add currency and emit signal
	CurrencyManager.add_currency("conversion", yield_curr)
	emit_signal("generator_updated", generator_id, yield_curr)
	
	print("Generator %s yielded: %.2f (total: %.2f)" % [generator_id, yield_curr, debug_data.total_yields[generator_id]])

func calculate_yield(gen: Dictionary) -> float:
	var level = gen["level"]
	var base = gen["base_yield"]
	var growth = gen["growth_factor"]
	var mult = gen.get("multiplier", 1.0)
	var tile_gap = abs(gen["tile_targets"][0] - gen["tile_targets"][1])
	var spread_bonus = 1.0 + (tile_gap / 10.0)  # Tunable formula

	var yield_value = base
	
	match gen["growth_curve"]:
		"exponential":
			yield_value = base * pow(growth, level)
		"linear":
			yield_value = base + (base * growth * level)

	#if upgrade_manager:
	#	mult *= upgrade_manager.get_generator_multiplier(gen["id"])

	var final_yield = yield_value * mult * spread_bonus
	return final_yield

func get_generator_by_id(id: String) -> Dictionary:
	for g in generators:
		if g["id"] == id:
			return g
	return {}

func level_up_generator(id: String) -> bool:
	var gen = get_generator_by_id(id)
	if gen.is_empty():
		print("Generator not found: ", id)
		return false
		
	var cost = gen.get("level_cost", 1.0)
	print("Attempting to level up %s - Cost: %.2f, Available: %.2f" % [id, cost, CurrencyManager.get_currency("conversion")])
	
	if CurrencyManager.spend_currency("conversion", cost):
		gen["level"] += 1
		gen["level_cost"] *= gen.get("cost_growth", 1.15)
		if gen["level"] == 1:
			gen["active"] = true
		print("Leveled up %s to level %d (new cost: %.2f)" % [gen.label, gen.level, gen.level_cost])
		return true
	else:
		print("Not enough currency to level up %s (cost: %.2f)" % [gen.label, cost])
		return false
			
func is_generator_active(id: String) -> bool:
	var gen = get_generator_by_id(id)
	return gen.get("active", false) and gen.get("level", 0) > 0

func refresh_generator_activation():
	var newly_unlocked = 0
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
			newly_unlocked += 1
			emit_signal("generator_unlocked", gen.id)
			
	if newly_unlocked > 0:
		debug_data.active_generators += newly_unlocked
		print("Newly unlocked generators: ", newly_unlocked)

# Debug functions for the debug panel
func get_debug_info() -> Dictionary:
	return {
		"active_generators": debug_data.active_generators,
		"total_lifetime_yield": debug_data.total_lifetime_yield,
		"generators": get_generator_debug_info()
	}

func get_generator_debug_info() -> Array:
	var info = []
	for gen in generators:
		if gen.get("active", false) and gen.get("level", 0) > 0:
			info.append({
				"id": gen.id,
				"label": gen.label,
				"level": gen.level,
				"last_yield": debug_data.last_yields.get(gen.id, 0.0),
				"total_yield": debug_data.total_yields.get(gen.id, 0.0),
				"tick_count": debug_data.tick_counts.get(gen.id, 0),
				"avg_yield": debug_data.total_yields.get(gen.id, 0.0) / max(1, debug_data.tick_counts.get(gen.id, 1))
			})
	return info

func get_total_yield_per_second() -> float:
	var total = 0.0
	for gen in generators:
		if gen.get("active", false) and gen.get("level", 0) > 0:
			var yield_per_tick = calculate_yield(gen)
			var ticks_per_second = 1.0 / gen.get("interval_seconds", 1.0)
			total += yield_per_tick * ticks_per_second
	return total
