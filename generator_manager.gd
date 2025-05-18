extends Node


signal generator_updated(id: String, new_yield: float)

var generators := []
var timers := {}

@onready var currency_manager := get_node("/root/CurrencyManager")
@onready var upgrade_manager := get_node_or_null("/root/UpgradeManager")

func _ready():
	load_generators()
	start_all_generators()

func load_generators():
	# In a real setup this would come from a JSON file.
	# For now, define directly:
	generators = [
		{"id": "gen_0", "label": "Basic Combiner", "tile_targets": [0, 1], "level": 1, "base_yield": 0.2, "growth_curve": "linear", "growth_factor": 1.0, "interval_seconds": 1.0, "multiplier": 1.0},
		{"id": "gen_1", "label": "Twin Amplifier", "tile_targets": [2, 3], "level": 1, "base_yield": 1.0, "growth_curve": "exponential", "growth_factor": 1.1, "interval_seconds": 2.0, "multiplier": 1.0},
		{"id": "gen_2", "label": "Prime Reactor", "tile_targets": [5, 7], "level": 1, "base_yield": 0.8, "growth_curve": "exponential", "growth_factor": 1.15, "interval_seconds": 3.0, "multiplier": 1.0},
		{"id": "gen_3", "label": "Echo Producer", "tile_targets": [9, 6], "level": 1, "base_yield": 1.5, "growth_curve": "linear", "growth_factor": 1.5, "interval_seconds": 4.0, "multiplier": 1.0},
		{"id": "gen_4", "label": "Recursive Synth", "tile_targets": [10, 4], "level": 1, "base_yield": 2.0, "growth_curve": "exponential", "growth_factor": 1.25, "interval_seconds": 6.0, "multiplier": 1.0},
		{"id": "gen_5", "label": "Singularity Driver", "tile_targets": [8, 11], "level": 1, "base_yield": 3.5, "growth_curve": "linear", "growth_factor": 2.0, "interval_seconds": 10.0, "multiplier": 1.0}
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

func _on_generator_tick(generator_id: String):
	var gen = get_generator_by_id(generator_id)
	if not gen:
		return

	var yield_curr = calculate_yield(gen)
	currency_manager.add_currency(yield_curr)
	emit_signal("generator_updated", generator_id, yield_curr)

func calculate_yield(gen: Dictionary) -> float:
	var level = gen["level"]
	var base = gen["base_yield"]
	var growth = gen["growth_factor"]
	var mult = gen.get("multiplier", 1.0)

	match gen["growth_curve"]:
		"exponential":
			base *= pow(growth, level)
		"linear":
			base *= level

	if upgrade_manager:
		mult *= upgrade_manager.get_generator_multiplier(gen["id"])

	return base * mult

func get_generator_by_id(id: String) -> Dictionary:
	for g in generators:
		if g["id"] == id:
			return g
	return {}

func level_up_generator(id: String):
	var gen = get_generator_by_id(id)
	if gen:
		gen["level"] += 1
