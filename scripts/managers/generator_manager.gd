extends Node

signal generator_updated(id: String, new_yield: float)
signal generator_unlocked(id: String)

var generator_collection: GeneratorCollection
var timers := {}
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
	start_all_generators()

func initialize_yield_algorithms():
	pass
# Add this method to GeneratorManager:
func check_for_newly_unlocked_generators():
	var newly_unlocked = []
	
	for gen in generator_collection.generators:
		var was_unlocked = gen.get("previously_unlocked", false)
		var is_now_unlocked = is_generator_unlocked(gen)
		
		if not was_unlocked and is_now_unlocked:
			gen["previously_unlocked"] = true
			newly_unlocked.append(gen.label)
	
	if newly_unlocked.size() > 0:
		print("Newly unlocked generators: ", newly_unlocked)
		# Emit signal to update UI
		emit_signal("generators_unlocked", newly_unlocked)

# Add this signal to your GeneratorManager:
signal generators_unlocked(generator_names: Array)
func load_generators():
	# Try to load from file first
	if ResourceLoader.exists("res://data/generators.tres"):
		generator_collection = load("res://data/generators.tres")
		print("Loaded generators from file")
	else:
		# Create default generators and save them
		print("Creating default generators...")
		generator_collection = GeneratorSetup.create_default_generators()
		GeneratorSetup.save_generators_to_file()
	
	# Initialize debug tracking
	for gen in generator_collection.generators:
		debug_data.total_yields[gen.id] = 0.0
		debug_data.tick_counts[gen.id] = 0
		debug_data.last_yields[gen.id] = 0.0

func start_all_generators():
	for gen_data in generator_collection.generators:
		var timer = Timer.new()
		timer.wait_time = gen_data.interval_seconds
		timer.autostart = true
		timer.one_shot = false
		timer.timeout.connect(_on_generator_tick.bind(gen_data.id))
		add_child(timer)
		timers[gen_data.id] = timer
		
func is_generator_unlocked(gen: GeneratorData) -> bool:
	# Get the highest tile the player has achieved
	var highest_tile = StatsTracker.get_highest_tile_achieved()
	
	# Check if both target tiles are achievable (less than or equal to highest achieved)
	for tile_target in gen.tile_targets:
		if tile_target > highest_tile:
			return false
	
	return true
func can_level_up_generator(gen: GeneratorData) -> bool:
	# Generator must be unlocked to level up
	if not is_generator_unlocked(gen):
		return false
	
	# Must have enough currency
	var cost = gen.level_cost
	if not CurrencyManager.can_afford("conversion", cost):
		return false
	
	return true
# Update the tick function to only generate for unlocked generators
func _on_generator_tick(generator_id: String):
	var gen = generator_collection.get_generator_by_id(generator_id)
	if not gen:
		return
	
	# Must be unlocked and leveled up to generate
	if not is_generator_unlocked(gen) or gen.level <= 0:
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

func calculate_yield(gen: GeneratorData) -> float:
	var base_yield = gen.calculate_level_yield()
	var spread_bonus = gen.get_spread_bonus()
	
	# Apply any upgrade multipliers here
	var upgrade_mult = 1.0
	#if upgrade_manager:
	#	upgrade_mult = upgrade_manager.get_generator_multiplier(gen.id)

	return base_yield * gen.multiplier * spread_bonus * upgrade_mult

func level_up_generator(id: String) -> bool:
	var gen = generator_collection.get_generator_by_id(id)
	if not gen:
		print("Generator not found: ", id)
		return false
	
	# Check if generator can be leveled up
	if not can_level_up_generator(gen):
		var status = get_generator_unlock_status(gen)
		if not status.unlocked:
			print("Generator %s is locked. Need tiles: %s" % [gen.label, status.blocking_tiles])
		elif not status.can_afford:
			print("Not enough currency to level up %s (cost: %.2f)" % [gen.label, gen.level_cost])
		return false
		
	print("Attempting to level up %s - Cost: %.2f, Available: %.2f" % [id, gen.level_cost, CurrencyManager.get_currency("conversion")])
	
	if CurrencyManager.spend_currency("conversion", gen.level_cost):
		gen.level += 1
		gen.level_cost *= gen.cost_growth
		
		# Activate generator when first leveled up
		if gen.level == 1:
			gen.active = true
			
		print("Leveled up %s to level %d (new cost: %.2f)" % [gen.label, gen.level, gen.level_cost])
		
		# Emit signal for UI updates
		emit_signal("generator_updated", id, calculate_yield(gen))
		return true
	else:
		print("Currency spend failed for %s" % gen.label)
		return false
			
func is_generator_active(id: String) -> bool:
	var gen = generator_collection.get_generator_by_id(id)
	return gen != null and gen.active and gen.level > 0

func refresh_generator_activation():
	var newly_unlocked = 0
	for gen in generator_collection.generators:
		if gen.active:
			continue

		var unlocked = true
		for tile in gen.tile_targets:
			if not StatsTracker.has_seen_tile(tile):
				unlocked = false
				break

		if unlocked:
			gen.active = true
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
	for gen in generator_collection.generators:
		if gen.active and gen.level > 0:
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
	for gen in generator_collection.generators:
		if gen.active and gen.level > 0:
			var yield_per_tick = calculate_yield(gen)
			var ticks_per_second = 1.0 / gen.interval_seconds
			total += yield_per_tick * ticks_per_second
	return total

# Save current generator state
func save_generator_state():
	ResourceSaver.save(generator_collection, "res://data/generators.tres")

func get_generator_unlock_status(gen: GeneratorData) -> Dictionary:
	var highest_tile = StatsTracker.get_highest_tile_achieved()
	var unlocked = is_generator_unlocked(gen)
	var can_afford = CurrencyManager.can_afford("conversion", gen.level_cost)
	
	var status = {
		"unlocked": unlocked,
		"can_afford": can_afford,
		"can_level_up": unlocked and can_afford,
		"highest_tile": highest_tile,
		"required_tiles": gen.tile_targets.duplicate(),
		"blocking_tiles": []
	}
	
	# Find which tiles are blocking the unlock
	if not unlocked:
		for tile_target in gen.tile_targets:
			if tile_target > highest_tile:
				status.blocking_tiles.append(tile_target)
	
	return status
