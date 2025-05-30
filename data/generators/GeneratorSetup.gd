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
	
	# Apply collection-wide modifiers (e.g., additional generators from keystones)
	apply_collection_modifiers(collection)
	
	return collection

# Creates a single generator with all applicable modifiers
static func create_modified_generator(base_template: Dictionary) -> GeneratorData:
	var gen = GeneratorData.new()
	
	# Start with base values
	apply_base_template(gen, base_template)
	
	# Apply modifiers in order of precedence (lowest to highest impact)
	apply_upgrade_modifiers(gen)
	apply_prestige_modifiers(gen)
	apply_ascension_modifiers(gen)
	apply_challenge_modifiers(gen)
	apply_lore_modifiers(gen)
	
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

# === UPGRADE TREE MODIFIERS ===
static func apply_upgrade_modifiers(gen: GeneratorData):
	if not UpgradeManager:
		return
	
	var gen_upgrades = UpgradeManager.get_generator_upgrades()
	
	# Generator Tree Tier 1: Basic yield multipliers
	if gen_upgrades.has("gen_yield_base"):
		gen.multiplier *= gen_upgrades.gen_yield_base
	
	if gen_upgrades.has("gen_frequency_boost"):
		gen.interval_seconds /= gen_upgrades.gen_frequency_boost
	
	# Generator Tree Tier 2: Targeted enhancements
	if gen_upgrades.has("gen_targeting_bonus"):
		var target_bonus = calculate_target_synergy_bonus(gen)
		gen.multiplier *= (1.0 + target_bonus)
	
	if gen_upgrades.has("gen_oscillation_enabled"):
		# Note: Oscillation would be handled in the yield calculation, not here
		# But we could modify the base parameters that affect it
		pass
	
	# Generator Tree Tier 3: Advanced modifications
	if gen_upgrades.has("gen_compound_scaling"):
		gen.growth_factor *= gen_upgrades.gen_compound_scaling
	
	# Generator Tree Keystone: Additional generators
	if gen_upgrades.has("gen_keystone_extra") and gen.id == "gen_0":
		# This would be handled in apply_collection_modifiers
		pass
	
	# Enhanced Keystone: Additional targeted tiles
	if gen_upgrades.has("gen_enhanced_keystone"):
		expand_tile_targets(gen)

# === PRESTIGE MODIFIERS ===
static func apply_prestige_modifiers(gen: GeneratorData):
	if not PrestigeManager:
		return
	
	var prestige_data = PrestigeManager.get_current_prestige_bonuses()
	
	# Reset Tree Tier 1: Post-reset currency boosts
	if prestige_data.has("reset_gen_boost"):
		gen.multiplier *= prestige_data.reset_gen_boost
	
	if prestige_data.has("reset_cost_reduction"):
		gen.level_cost *= (1.0 - prestige_data.reset_cost_reduction)
		gen.cost_growth = max(1.01, gen.cost_growth - prestige_data.reset_cost_reduction * 0.1)
	
	# Reset Tree Tier 2: Persistent generators
	if prestige_data.has("kept_generators") and gen.id in prestige_data.kept_generators:
		gen.level = prestige_data.kept_generator_levels.get(gen.id, 1)
		gen.active = true
	
	# Reset Tree Tier 3: Auto-reset optimizations
	if prestige_data.has("auto_reset_efficiency"):
		gen.interval_seconds *= (1.0 - prestige_data.auto_reset_efficiency * 0.1)

# === ASCENSION MODIFIERS ===
static func apply_ascension_modifiers(gen: GeneratorData):
	if not AscensionManager:
		return
	
	var ascension_data = AscensionManager.get_current_ascension_bonuses()
	
	# Apex Point bonuses
	if ascension_data.has("apex_generator_power"):
		gen.base_yield *= pow(1.1, ascension_data.apex_generator_power)
	
	if ascension_data.has("apex_algorithm_seeds"):
		# Custom seeded algorithms - would affect yield calculation patterns
		gen.algorithm_seed = ascension_data.get("custom_seed_" + gen.id, 0)
	
	# Reality modifications
	if ascension_data.has("reality_breach_unlocked"):
		apply_reality_breach_modifiers(gen, ascension_data)

# === CHALLENGE MODIFIERS (DISCIPLINE TREE) ===
static func apply_challenge_modifiers(gen: GeneratorData):
	if not ChallengeManager:
		return
	
	var active_challenges = ChallengeManager.get_active_challenges()
	var completed_challenges = ChallengeManager.get_completed_challenges()
	
	# Active challenge penalties
	for challenge in active_challenges:
		match challenge.type:
			"single_generator":
				if gen.id != challenge.allowed_generator:
					gen.active = false
			"prime_obstacles":
				if is_prime_number(gen.tile_targets[0]) or is_prime_number(gen.tile_targets[1]):
					gen.multiplier *= 0.5
			"time_constraint":
				gen.interval_seconds *= 1.5
	
	# Completed challenge bonuses (permanent)
	for challenge in completed_challenges:
		match challenge.type:
			"risk_reward_mastery":
				gen.multiplier *= (1.0 + challenge.completion_bonus)
			"multi_merge_master":
				if gen.tile_targets.size() >= 2:
					gen.growth_factor *= 1.1

# === LORE TREE MODIFIERS ===
static func apply_lore_modifiers(gen: GeneratorData):
	if not LoreManager:
		return
	
	var lore_data = LoreManager.get_unlocked_insights()
	
	# Lore Tree Tier 1: Basic visibility (no mechanical changes)
	# Lore Tree Tier 2: Deeper insights reveal optimization opportunities
	if lore_data.has("optimal_targeting_revealed"):
		optimize_tile_targeting(gen)
	
	# Lore Tree Tier 3: Predictive analytics
	if lore_data.has("predictive_scaling_unlocked"):
		gen.predictive_data = calculate_predictive_scaling(gen)
	
	# Lore Keystone: Custom algorithms
	if lore_data.has("custom_algorithms_unlocked"):
		apply_custom_algorithm(gen, lore_data.get("custom_algorithm_" + gen.id))

# === COLLECTION-WIDE MODIFIERS ===
static func apply_collection_modifiers(collection: GeneratorCollection):
	if not UpgradeManager:
		return
	
	var upgrades = UpgradeManager.get_generator_upgrades()
	
	# Generator Keystone: Add additional generator
	if upgrades.has("gen_keystone_extra"):
		var extra_gen = create_keystone_generator(upgrades.gen_keystone_extra)
		collection.generators.append(extra_gen)
	
	# Ascension: Board type modifications affect all generators
	if AscensionManager and AscensionManager.has_custom_board_config():
		var board_config = AscensionManager.get_board_config()
		adjust_generators_for_board(collection, board_config)

# === HELPER FUNCTIONS ===
static func calculate_target_synergy_bonus(gen: GeneratorData) -> float:
	if gen.tile_targets.size() < 2:
		return 0.0
	
	# Check if current board state has synergy with these targets
	var synergy = 0.0
	for target in gen.tile_targets:
		if StatsTracker and StatsTracker.get_tile_frequency(target) > 0.1:
			synergy += 0.2
	
	return synergy

static func expand_tile_targets(gen: GeneratorData):
	# Enhanced Keystone adds additional tile targets
	var current_targets = gen.tile_targets.duplicate()
	for target in current_targets:
		var adjacent_target = target + 1
		if adjacent_target not in gen.tile_targets and adjacent_target <= 15:
			gen.tile_targets.append(adjacent_target)

static func create_keystone_generator(keystone_data: Dictionary) -> GeneratorData:
	var gen = GeneratorData.new()
	gen.id = "gen_keystone_" + str(keystone_data.get("index", 0))
	gen.label = keystone_data.get("label", "Keystone Generator")
	gen.tile_targets = keystone_data.get("targets", [12, 13])
	gen.base_yield = keystone_data.get("yield", 5.0)
	gen.growth_curve = keystone_data.get("curve", "exponential")
	gen.growth_factor = keystone_data.get("factor", 1.3)
	gen.interval_seconds = keystone_data.get("interval", 8.0)
	gen.level_cost = keystone_data.get("cost", 15.0)
	gen.cost_growth = keystone_data.get("growth", 1.28)
	gen.active = true
	gen.level = 1
	gen.multiplier = 1.0
	return gen

static func apply_reality_breach_modifiers(gen: GeneratorData, ascension_data: Dictionary):
	# Reality Breach allows fundamental changes to generator behavior
	if ascension_data.has("reality_custom_curves"):
		gen.growth_curve = ascension_data.get("custom_curve_" + gen.id, gen.growth_curve)
	
	if ascension_data.has("reality_reverse_scaling"):
		# Reverse the cost scaling - gets cheaper as you level up
		gen.cost_growth = 1.0 / gen.cost_growth
	
	if ascension_data.has("reality_negative_intervals"):
		# Generators can tick multiple times per second
		gen.interval_seconds = min(gen.interval_seconds, 0.1)

static func optimize_tile_targeting(gen: GeneratorData):
	# Lore insights can optimize tile targeting based on play patterns
	if not StatsTracker:
		return
	
	var tile_stats = StatsTracker.get_tile_usage_stats()
	var best_targets = []
	
	# Find the most frequently merged tiles that are close to current targets
	for target in gen.tile_targets:
		var nearby_tiles = range(max(0, target - 2), min(16, target + 3))
		var best_nearby = target
		var best_frequency = tile_stats.get(target, 0.0)
		
		for nearby in nearby_tiles:
			var frequency = tile_stats.get(nearby, 0.0)
			if frequency > best_frequency:
				best_frequency = frequency
				best_nearby = nearby
		
		best_targets.append(best_nearby)
	
	gen.tile_targets = best_targets

static func calculate_predictive_scaling(gen: GeneratorData) -> Dictionary:
	# Lore tree predictive analytics
	return {
		"optimal_level": calculate_optimal_level(gen),
		"roi_breakpoint": calculate_roi_breakpoint(gen),
		"synergy_forecast": calculate_synergy_forecast(gen)
	}

static func apply_custom_algorithm(gen: GeneratorData, algorithm_data):
	if not algorithm_data:
		return
	
	# Custom algorithms from Lore Keystone
	gen.custom_algorithm = algorithm_data
	gen.algorithm_type = algorithm_data.get("type", "default")

static func adjust_generators_for_board(collection: GeneratorCollection, board_config: Dictionary):
	# Ascension board modifications affect all generators
	var board_size = board_config.get("size", 16)  # 4x4 = 16
	var max_tile = board_config.get("max_tile", 15)
	
	for gen in collection.generators:
		# Adjust tile targets for different board sizes
		var adjusted_targets = []
		for target in gen.tile_targets:
			var adjusted = min(target, max_tile)
			adjusted_targets.append(adjusted)
		gen.tile_targets = adjusted_targets

static func is_prime_number(n: int) -> bool:
	if n < 2:
		return false
	for i in range(2, int(sqrt(n)) + 1):
		if n % i == 0:
			return false
	return true

static func calculate_optimal_level(gen: GeneratorData) -> int:
	# Placeholder for complex optimization
	return 10

static func calculate_roi_breakpoint(gen: GeneratorData) -> float:
	# Placeholder for ROI calculation
	return gen.level_cost * 5.0

static func calculate_synergy_forecast(gen: GeneratorData) -> Dictionary:
	# Placeholder for synergy prediction
	return {"forecast": "positive", "confidence": 0.8}

# === PUBLIC INTERFACE ===
static func create_default_generators() -> GeneratorCollection:
	return create_generators_with_modifiers()

static func save_generators_to_file():
	var generators = create_generators_with_modifiers()
	var result = ResourceSaver.save(generators, "res://data/generators.tres")
	if result == OK:
		print("Generators saved successfully!")
	else:
		print("Failed to save generators: ", result)

# Refresh generators when game state changes (upgrades, prestige, etc.)
static func refresh_generators_for_current_state() -> GeneratorCollection:
	print("Refreshing generators with current modifiers...")
	return create_generators_with_modifiers()
