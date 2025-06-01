# res://data/generator_setup.gd
# Centralized generator creation with modifier injection from all game systems
# This handles base generation + modifications from upgrades, prestige, ascension, etc.

class_name GeneratorSetup
extends RefCounted

# Base generator templates - never modified directly
static var BASE_GENERATORS := [
	{
		"id": "gen_0", "label": "Basic Combiner",
		"tile_targets": [0, 1], "base_yield": 0.2, "growth_curve": "linear", 
		"growth_factor": 1.0, "interval_seconds": 1.0, "level_cost": 1.0, "cost_growth": 1.12,
		"unlock_requirements": [], "default_active": true
	},
	{
		"id": "gen_1", "label": "Twin Amplifier", 
		"tile_targets": [2, 3], "base_yield": 1.0, "growth_curve": "exponential", 
		"growth_factor": 1.1, "interval_seconds": 2.0, "level_cost": 2.0, "cost_growth": 1.15,
		"unlock_requirements": [2, 3], "default_active": false
	},
	{
		"id": "gen_2", "label": "Prime Reactor",
		"tile_targets": [5, 7], "base_yield": 0.8, "growth_curve": "exponential",
		"growth_factor": 1.15, "interval_seconds": 3.0, "level_cost": 3.5, "cost_growth": 1.18,
		"unlock_requirements": [5, 7], "default_active": false
	},
	{
		"id": "gen_3", "label": "Echo Producer",
		"tile_targets": [9, 6], "base_yield": 1.5, "growth_curve": "linear",
		"growth_factor": 1.5, "interval_seconds": 4.0, "level_cost": 5.0, "cost_growth": 1.2,
		"unlock_requirements": [9, 6], "default_active": false
	},
	{
		"id": "gen_4", "label": "Recursive Synth",
		"tile_targets": [10, 4], "base_yield": 2.0, "growth_curve": "exponential",
		"growth_factor": 1.25, "interval_seconds": 6.0, "level_cost": 7.5, "cost_growth": 1.22,
		"unlock_requirements": [10, 4], "default_active": false
	},
	{
		"id": "gen_5", "label": "Singularity Driver",
		"tile_targets": [8, 11], "base_yield": 3.5, "growth_curve": "linear",
		"growth_factor": 2.0, "interval_seconds": 10.0, "level_cost": 10.0, "cost_growth": 1.25,
		"unlock_requirements": [8, 11], "default_active": false
	}
]

# Main creation function - applies all modifiers from all systems
static func create_generators_with_modifiers() -> GeneratorCollection:
	var collection = GeneratorCollection.new()
	collection.generators = []
	
	for base_gen in BASE_GENERATORS:
		var modified_gen = create_modified_generator(base_gen)
		collection.generators.append(modified_gen)
	
	
	return collection

# Creates a single generator with all applicable modifiers
static func create_modified_generator(base_template: Dictionary) -> GeneratorData:
	var gen = GeneratorData.new()
	
	# Start with base values
	apply_base_template(gen, base_template)
	
	# Apply modifiers in order of precedence (lowest to highest impact)

	
	return gen

# === BASE TEMPLATE APPLICATION ===
static func apply_base_template(gen: GeneratorData, template: Dictionary):
	gen.id = template.get("id", "")
	gen.label = template.get("label", "")
	gen.tile_targets = template.get("tile_targets", [])
	gen.base_yield = template.get("base_yield", 1.0)
	gen.growth_curve = template.get("growth_curve", "linear")
	gen.growth_factor = template.get("growth_factor", 1.0)
	gen.interval_seconds = template.get("interval_seconds", 1.0)
	gen.level_cost = template.get("level_cost", 1.0)
	gen.cost_growth = template.get("cost_growth", 1.15)
	gen.active = template.get("default_active", false)
	gen.level = 1 if gen.active else 0
	gen.multiplier = 1.0


# === PUBLIC INTERFACE ===
static func create_default_generators() -> GeneratorCollection:
	return create_generators_with_modifiers()

static func save_generators_to_file():
	var generators = create_generators_with_modifiers()
	var result = ResourceSaver.save(generators, "res://data/generators/generators.tres")
	if result == OK:
		print("Generators saved successfully!")
	else:
		print("Failed to save generators: ", result)

# Refresh generators when game state changes (upgrades, prestige, etc.)
static func refresh_generators_for_current_state() -> GeneratorCollection:
	print("Refreshing generators with current modifiers...")
	return create_generators_with_modifiers()
