class_name ConversionTree
extends SkillTree

## Conversion upgrade tree - economic efficiency and resource optimization
## Focuses on improving score-to-currency conversion rates and batch processing bonuses

func _init(currency_mgr: CurrencyManager):
	super._init("Conversion", currency_mgr)

func _get_xp_currency_type() -> String:
	return "conversion_xp"

## Define all Conversion upgrades
func _initialize_upgrades() -> void:
	upgrade_definitions = {
		# Tier 1 Upgrades
		"t1_base_boost": _create_upgrade_definition(
			"t1_base_boost",
			"Base Boost",
			"Increase base conversion rate by +20%",
			40,
			1
		),
		
		"t1_score_multiplier": _create_upgrade_definition(
			"t1_score_multiplier",
			"Score Multiplier", 
			"Games with 10,000+ points get +50% conversion bonus",
			65,
			1
		),
		
		"t1_efficiency_tracking": _create_upgrade_definition(
			"t1_efficiency_tracking",
			"Efficiency Tracking",
			"Unlock detailed conversion statistics and optimization hints",
			30,
			1
		),
		
		"t1_batch_bonus": _create_upgrade_definition(
			"t1_batch_bonus",
			"Batch Bonus",
			"Gain +5% conversion bonus per game when converting 3+ games at once",
			55,
			1
		)
	}

## Calculate active bonuses from purchased upgrades  
func _calculate_active_bonuses() -> void:
	active_bonuses.clear()
	
	# Base conversion rate boost
	if tree_data.is_upgrade_purchased("t1_base_boost"):
		active_bonuses["base_conversion_multiplier"] = 1.20
	
	# High score bonus
	if tree_data.is_upgrade_purchased("t1_score_multiplier"):
		active_bonuses["high_score_bonus"] = 1.50
		active_bonuses["high_score_threshold"] = 10000
	
	# Efficiency tracking unlock
	if tree_data.is_upgrade_purchased("t1_efficiency_tracking"):
		active_bonuses["detailed_stats_enabled"] = true
		active_bonuses["optimization_hints_enabled"] = true
	
	# Batch conversion bonus
	if tree_data.is_upgrade_purchased("t1_batch_bonus"):
		active_bonuses["batch_bonus_per_game"] = 0.05
		active_bonuses["batch_minimum"] = 3

## Apply upgrade effects to game systems
func _apply_upgrade_effects(upgrade_id: String) -> void:
	match upgrade_id:
		"t1_base_boost":
			_notify_conversion_rate_updated()
		"t1_score_multiplier":
			_notify_score_bonus_unlocked()
		"t1_efficiency_tracking":
			_notify_detailed_tracking_unlocked() 
		"t1_batch_bonus":
			_notify_batch_system_unlocked()

## Conversion calculation methods for CurrencyManager integration
func calculate_conversion_multiplier(game_score: int, games_in_batch: int = 1) -> float:
	var multiplier = 1.0
	
	# Apply base conversion boost
	if active_bonuses.has("base_conversion_multiplier"):
		multiplier *= active_bonuses["base_conversion_multiplier"]
	
	# Apply high score bonus
	if active_bonuses.has("high_score_bonus") and game_score >= active_bonuses.get("high_score_threshold", 10000):
		multiplier *= active_bonuses["high_score_bonus"]
	
	# Apply batch bonus
	if active_bonuses.has("batch_bonus_per_game") and games_in_batch >= active_bonuses.get("batch_minimum", 3):
		var batch_multiplier = 1.0 + (active_bonuses["batch_bonus_per_game"] * games_in_batch)
		multiplier *= batch_multiplier
	
	return multiplier

func calculate_batch_conversion(game_scores: Array) -> Dictionary:
	var total_base_value = 0.0
	var total_converted_value = 0.0
	var games_count = game_scores.size()
	
	for score in game_scores:
		var base_value = currency_manager.convert_score_to_currency(score)
		var conversion_multiplier = calculate_conversion_multiplier(score, games_count)
		var converted_value = base_value * conversion_multiplier
		
		total_base_value += base_value
		total_converted_value += converted_value
	
	return {
		"base_value": total_base_value,
		"converted_value": total_converted_value,
		"bonus_value": total_converted_value - total_base_value,
		"total_multiplier": total_converted_value / total_base_value if total_base_value > 0 else 1.0,
		"games_processed": games_count
	}

func is_detailed_tracking_enabled() -> bool:
	return active_bonuses.get("detailed_stats_enabled", false)

func is_optimization_hints_enabled() -> bool:
	return active_bonuses.get("optimization_hints_enabled", false)

## XP gain methods for conversion activities
func gain_xp_from_conversion(converted_amount: float, games_converted: int) -> void:
	var xp_amount = 0
	
	# Base XP from conversion value (1 XP per 10 currency)
	xp_amount += int(converted_amount / 10)
	
	# Bonus XP for batch conversions
	if games_converted >= 3:
		xp_amount += games_converted * 3
	
	# Bonus XP for large conversions
	if converted_amount >= 1000:
		xp_amount += 10
	if converted_amount >= 5000:
		xp_amount += 25
	
	if xp_amount > 0:
		gain_xp(xp_amount)

func gain_xp_from_efficiency(efficiency_rating: float) -> void:
	# XP for maintaining good conversion efficiency
	var xp_amount = 0
	
	if efficiency_rating >= 1.5:  # 50% bonus or better
		xp_amount += 5
	if efficiency_rating >= 2.0:  # 100% bonus or better
		xp_amount += 10
	
	if xp_amount > 0:
		gain_xp(xp_amount)

## Optimization hint generation
func generate_optimization_hints(recent_conversions: Array) -> Array:
	if not is_optimization_hints_enabled():
		return []
	
	var hints = []
	
	# Analyze recent conversion patterns
	if recent_conversions.size() >= 5:
		var avg_batch_size = 0
		var total_efficiency = 0.0
		
		for conversion in recent_conversions:
			avg_batch_size += conversion.get("games_count", 1)
			total_efficiency += conversion.get("efficiency", 1.0)
		
		avg_batch_size = avg_batch_size / recent_conversions.size()
		var avg_efficiency = total_efficiency / recent_conversions.size()
		
		# Generate specific hints
		if avg_batch_size < 3 and active_bonuses.has("batch_bonus_per_game"):
			hints.append("Tip: Convert 3+ games at once for batch bonuses!")
		
		if avg_efficiency < 1.3:
			hints.append("Tip: Focus on higher-scoring games for better conversion rates")
		
		# Check for high-score threshold optimization
		if active_bonuses.has("high_score_threshold"):
			var threshold = active_bonuses["high_score_threshold"]
			var below_threshold_count = 0
			for conversion in recent_conversions:
				if conversion.get("max_score", 0) < threshold:
					below_threshold_count += 1
			
			if below_threshold_count > recent_conversions.size() / 2:
				hints.append("Tip: Aim for " + str(threshold) + "+ point games for score multiplier bonus!")
	
	return hints

## Private notification methods for system integration
func _notify_conversion_rate_updated() -> void:
	# Signal CurrencyManager to update conversion efficiency
	print("Conversion Tree: Base conversion rate increased by 20%")

func _notify_score_bonus_unlocked() -> void:
	# Signal that high-score conversion bonus is available
	print("Conversion Tree: High score multiplier unlocked - 10,000+ point games get bonus")

func _notify_detailed_tracking_unlocked() -> void:
	# Signal UI to show detailed conversion statistics
	print("Conversion Tree: Detailed tracking unlocked - showing conversion analytics")

func _notify_batch_system_unlocked() -> void:
	# Signal that batch conversion bonuses are available
	print("Conversion Tree: Batch bonus unlocked - converting multiple games gives bonus")

## Debug and utility methods
func get_conversion_stats() -> Dictionary:
	return {
		"base_boost_active": active_bonuses.has("base_conversion_multiplier"),
		"score_bonus_active": active_bonuses.has("high_score_bonus"),
		"detailed_tracking": is_detailed_tracking_enabled(),
		"batch_bonus_active": active_bonuses.has("batch_bonus_per_game"),
		"current_bonuses": active_bonuses
	}
