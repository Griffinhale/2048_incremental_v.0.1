class_name GeneratorsTree
extends SkillTree

## Generator upgrade tree - passive income scaling and idle progression optimization
## Focuses on improving generator yield, frequency, and targeting effectiveness

func _init(currency_mgr: CurrencyManager):
	super._init("Generators", currency_mgr)

func _get_xp_currency_type() -> String:
	return "generator_xp"

## Define all Generator upgrades
func _initialize_upgrades() -> void:
	upgrade_definitions = {
		# Tier 1 Upgrades
		"t1_yield_amplifier": _create_upgrade_definition(
			"t1_yield_amplifier",
			"Yield Amplifier",
			"Increase base yield for all generators by +30%",
			45,
			1
		),
		
		"t1_frequency_boost": _create_upgrade_definition(
			"t1_frequency_boost",
			"Frequency Boost",
			"All generators tick 20% faster, producing currency more often",
			50,
			1
		),
		
		"t1_target_bonus": _create_upgrade_definition(
			"t1_target_bonus", 
			"Target Bonus",
			"Generators gain +15% yield when their targeted tiles are on the board",
			60,
			1
		),
		
		"t1_collection_synergy": _create_upgrade_definition(
			"t1_collection_synergy",
			"Collection Synergy",
			"Each active generator provides +2% yield bonus to all other generators",
			70,
			1
		)
	}

## Calculate active bonuses from purchased upgrades
func _calculate_active_bonuses() -> void:
	active_bonuses.clear()
	
	# Base yield amplification
	if tree_data.is_upgrade_purchased("t1_yield_amplifier"):
		active_bonuses["base_yield_multiplier"] = 1.30
	
	# Frequency/speed boost  
	if tree_data.is_upgrade_purchased("t1_frequency_boost"):
		active_bonuses["frequency_multiplier"] = 1.20
		active_bonuses["interval_reduction"] = 0.80  # 20% faster = 80% interval
	
	# Targeting effectiveness boost
	if tree_data.is_upgrade_purchased("t1_target_bonus"):
		active_bonuses["target_bonus_multiplier"] = 1.15
		active_bonuses["targeting_enabled"] = true
	
	# Collection synergy bonus
	if tree_data.is_upgrade_purchased("t1_collection_synergy"):
		active_bonuses["synergy_per_generator"] = 0.02
		active_bonuses["synergy_enabled"] = true

## Apply upgrade effects to game systems
func _apply_upgrade_effects(upgrade_id: String) -> void:
	match upgrade_id:
		"t1_yield_amplifier":
			_notify_yield_boost_applied()
		"t1_frequency_boost":
			_notify_frequency_boost_applied()
		"t1_target_bonus":
			_notify_targeting_system_unlocked()
		"t1_collection_synergy":
			_notify_synergy_system_unlocked()

## Generator bonus calculation methods for GeneratorManager integration
func calculate_generator_yield_multiplier(generator_data: GeneratorData, active_generator_count: int, board_tiles: Array = []) -> float:
	var multiplier = 1.0
	
	# Apply base yield amplification
	if active_bonuses.has("base_yield_multiplier"):
		multiplier *= active_bonuses["base_yield_multiplier"]
	
	# Apply targeting bonus if applicable
	if active_bonuses.has("target_bonus_multiplier") and _is_target_on_board(generator_data, board_tiles):
		multiplier *= active_bonuses["target_bonus_multiplier"]
	
	# Apply collection synergy bonus
	if active_bonuses.has("synergy_per_generator") and active_generator_count > 1:
		var synergy_bonus = 1.0 + (active_bonuses["synergy_per_generator"] * (active_generator_count - 1))
		multiplier *= synergy_bonus
	
	return multiplier

func calculate_generator_frequency_multiplier() -> float:
	return active_bonuses.get("frequency_multiplier", 1.0)

func calculate_generator_interval_multiplier() -> float:
	return active_bonuses.get("interval_reduction", 1.0)

func is_targeting_enabled() -> bool:
	return active_bonuses.get("targeting_enabled", false)

func is_synergy_enabled() -> bool:
	return active_bonuses.get("synergy_enabled", false)

## Advanced generator calculations
func calculate_collection_wide_bonuses(generator_collection: Array) -> Dictionary:
	var bonuses = {
		"total_yield_multiplier": 1.0,
		"frequency_bonus": 1.0,
		"synergy_bonus": 0.0,
		"active_count": 0
	}
	
	# Count active generators
	for generator in generator_collection:
		if generator.active:
			bonuses["active_count"] += 1
	
	# Calculate synergy bonus
	if active_bonuses.has("synergy_per_generator") and bonuses["active_count"] > 1:
		bonuses["synergy_bonus"] = active_bonuses["synergy_per_generator"] * (bonuses["active_count"] - 1)
		bonuses["total_yield_multiplier"] += bonuses["synergy_bonus"]
	
	# Apply base yield multiplier
	if active_bonuses.has("base_yield_multiplier"):
		bonuses["total_yield_multiplier"] *= active_bonuses["base_yield_multiplier"]
	
	# Apply frequency bonus
	if active_bonuses.has("frequency_multiplier"):
		bonuses["frequency_bonus"] = active_bonuses["frequency_multiplier"]
	
	return bonuses

## XP gain methods for generator activities
func gain_xp_from_generator_yield(yield_amount: float, generator_count: int) -> void:
	var xp_amount = 0
	
	# Base XP from yield (1 XP per 50 yield)
	xp_amount += int(yield_amount / 50)
	
	# Bonus XP for having multiple generators
	if generator_count >= 2:
		xp_amount += generator_count
	
	# Bonus XP for high yields
	if yield_amount >= 100:
		xp_amount += 3
	if yield_amount >= 500:
		xp_amount += 8
	
	if xp_amount > 0:
		gain_xp(xp_amount)

func gain_xp_from_generator_upgrade(upgrade_cost: float) -> void:
	# XP for upgrading generators (encourages investment)
	var xp_amount = max(1, int(upgrade_cost / 100))
	gain_xp(xp_amount)

func gain_xp_from_targeting_effectiveness(effectiveness_rating: float) -> void:
	# XP for effective targeting when bonus is active
	if not is_targeting_enabled():
		return
	
	var xp_amount = 0
	if effectiveness_rating >= 0.5:  # 50% of targets hit
		xp_amount += 2
	if effectiveness_rating >= 0.8:  # 80% of targets hit
		xp_amount += 5
	
	if xp_amount > 0:
		gain_xp(xp_amount)

## Utility methods for targeting system
func _is_target_on_board(generator_data: GeneratorData, board_tiles: Array) -> bool:
	if not is_targeting_enabled():
		return false
	
	for target_value in generator_data.tile_targets:
		for tile_value in board_tiles:
			if tile_value == target_value:
				return true
	
	return false

func calculate_targeting_effectiveness(generator_data: GeneratorData, board_tiles: Array) -> float:
	if not is_targeting_enabled() or generator_data.tile_targets.is_empty():
		return 0.0
	
	var targets_found = 0
	for target_value in generator_data.tile_targets:
		if target_value in board_tiles:
			targets_found += 1
	
	return float(targets_found) / float(generator_data.tile_targets.size())

## Performance optimization for idle play
func get_idle_optimization_recommendations(generator_collection: Array) -> Array:
	var recommendations = []
	
	# Check if synergy could be improved
	if is_synergy_enabled():
		var active_count = 0
		for generator in generator_collection:
			if generator.active:
				active_count += 1
		
		if active_count < generator_collection.size():
			recommendations.append("Activate more generators to increase synergy bonuses")
	
	# Check targeting effectiveness
	if is_targeting_enabled():
		recommendations.append("Focus gameplay on tiles that match your generator targets")
	
	# Check for upgrade opportunities
	var total_levels = 0
	for generator in generator_collection:
		total_levels += generator.level
	
	if total_levels < generator_collection.size() * 5:
		recommendations.append("Consider upgrading generators for better yield")
	
	return recommendations

## Private notification methods for system integration
func _notify_yield_boost_applied() -> void:
	# Signal GeneratorManager to recalculate all yields
	print("Generator Tree: Yield amplifier applied - all generators +30% base yield")

func _notify_frequency_boost_applied() -> void:
	# Signal GeneratorManager to update timer intervals
	print("Generator Tree: Frequency boost applied - generators tick 20% faster")

func _notify_targeting_system_unlocked() -> void:
	# Signal that targeting bonuses should be calculated
	print("Generator Tree: Targeting bonus unlocked - generators gain yield from matching tiles")

func _notify_synergy_system_unlocked() -> void:
	# Signal that collection synergy should be calculated
	print("Generator Tree: Collection synergy unlocked - generators boost each other")

## Debug and utility methods
func get_generator_tree_stats() -> Dictionary:
	return {
		"yield_boost_active": active_bonuses.has("base_yield_multiplier"),
		"frequency_boost_active": active_bonuses.has("frequency_multiplier"), 
		"targeting_enabled": is_targeting_enabled(),
		"synergy_enabled": is_synergy_enabled(),
		"current_bonuses": active_bonuses
	}
