class_name ActiveTree
extends SkillTree

## Active Play upgrade tree - engagement rewards through combo mechanics and active gameplay bonuses
## Focuses on rewarding skilled play and providing immediate feedback for player actions

func _init(currency_mgr: CurrencyManager):
	super._init("Active", currency_mgr)

func _get_xp_currency_type() -> String:
	return "active_xp"

## Define all Active Play upgrades
func _initialize_upgrades() -> void:
	upgrade_definitions = {
		# Tier 1 Upgrades
		"t1_combo_starter": _create_upgrade_definition(
			"t1_combo_starter",
			"Combo Starter",
			"Gain +25% score when merging 3+ tiles in a single move",
			50,
			1
		),
		
		"t1_move_efficiency": _create_upgrade_definition(
			"t1_move_efficiency", 
			"Move Efficiency",
			"First 10 moves of each game provide +15% score bonus",
			75,
			1
		),
		
		"t1_queue_preview": _create_upgrade_definition(
			"t1_queue_preview",
			"Queue Preview", 
			"Unlock the ability to see upcoming tiles in queue",
			60,
			1
		),
		
		"t1_precision_play": _create_upgrade_definition(
			"t1_precision_play",
			"Precision Play",
			"Gain +10% score for merges that create exactly the tile needed for combos",
			80,
			1
		)
	}

## Calculate active bonuses from purchased upgrades
func _calculate_active_bonuses() -> void:
	active_bonuses.clear()
	
	# Combo Starter bonus
	if tree_data.is_upgrade_purchased("t1_combo_starter"):
		active_bonuses["combo_multiplier"] = 1.25
		active_bonuses["combo_threshold"] = 3
	
	# Move Efficiency bonus  
	if tree_data.is_upgrade_purchased("t1_move_efficiency"):
		active_bonuses["early_move_bonus"] = 1.15
		active_bonuses["early_move_count"] = 10
	
	# Queue Preview unlock
	if tree_data.is_upgrade_purchased("t1_queue_preview"):
		active_bonuses["queue_enabled"] = true
		active_bonuses["queue_length"] = 3
	
	# Precision Play bonus
	if tree_data.is_upgrade_purchased("t1_precision_play"):
		active_bonuses["precision_multiplier"] = 1.10

## Apply upgrade effects to game systems
func _apply_upgrade_effects(upgrade_id: String) -> void:
	match upgrade_id:
		"t1_combo_starter":
			_notify_combo_system_unlocked()
		"t1_move_efficiency": 
			_notify_move_efficiency_unlocked()
		"t1_queue_preview":
			_notify_queue_system_unlocked()
		"t1_precision_play":
			_notify_precision_system_unlocked()

## Bonus calculation methods for GameBoard integration
func calculate_move_score_bonus(base_score: int, move_count: int, tiles_merged: int) -> float:
	var bonus_multiplier = 1.0
	
	# Apply combo bonus
	if active_bonuses.has("combo_multiplier") and tiles_merged >= active_bonuses.get("combo_threshold", 3):
		bonus_multiplier *= active_bonuses["combo_multiplier"]
	
	# Apply early move bonus
	if active_bonuses.has("early_move_bonus") and move_count <= active_bonuses.get("early_move_count", 10):
		bonus_multiplier *= active_bonuses["early_move_bonus"]
	
	# Apply precision bonus (would need additional logic to detect "precision" merges)
	if active_bonuses.has("precision_multiplier"):
		# This would be calculated based on board state analysis
		# For now, apply to high-value merges as a proxy
		if base_score > 100:
			bonus_multiplier *= active_bonuses["precision_multiplier"]
	
	return bonus_multiplier

func is_queue_unlocked() -> bool:
	return active_bonuses.get("queue_enabled", false)

func get_queue_length() -> int:
	return active_bonuses.get("queue_length", 0)

## XP gain methods for active play actions
func gain_xp_from_move(score_gained: int, tiles_merged: int) -> void:
	var xp_amount = 0
	
	# Base XP from score (1 XP per 100 score)
	xp_amount += score_gained / 100
	
	# Bonus XP for combos
	if tiles_merged >= 3:
		xp_amount += tiles_merged * 2
	
	# Bonus XP for high-value merges  
	if score_gained > 500:
		xp_amount += 5
	
	if xp_amount > 0:
		gain_xp(xp_amount)

func gain_xp_from_game_completion(final_score: int, moves_made: int, max_tile: int) -> void:
	var xp_amount = 0
	
	# Base completion XP
	xp_amount += 10
	
	# Score milestone bonuses
	if final_score >= 1000:
		xp_amount += 5
	if final_score >= 5000:
		xp_amount += 10
	if final_score >= 10000:
		xp_amount += 20
	
	# Efficiency bonus (high score with few moves)
	var efficiency = float(final_score) / float(moves_made) if moves_made > 0 else 0
	if efficiency > 100:
		xp_amount += int(efficiency / 50)
	
	# Tile achievement bonuses
	if max_tile >= 512:
		xp_amount += 15
	if max_tile >= 1024:
		xp_amount += 25
	
	if xp_amount > 0:
		gain_xp(xp_amount)

## Private notification methods for system integration
func _notify_combo_system_unlocked() -> void:
	# Signal that combo tracking should be enabled
	print("Active Tree: Combo system unlocked - tracking 3+ tile merges")

func _notify_move_efficiency_unlocked() -> void:
	# Signal that move counting bonus should be applied
	print("Active Tree: Move efficiency unlocked - early moves get bonus")

func _notify_queue_system_unlocked() -> void:
	# Signal to Spawner and UI that queue should be visible
	print("Active Tree: Queue preview unlocked - showing upcoming tiles")

func _notify_precision_system_unlocked() -> void:
	# Signal that precision merge detection should be enabled
	print("Active Tree: Precision play unlocked - tracking strategic merges")

## Debug and utility methods
func get_active_play_stats() -> Dictionary:
	return {
		"combo_bonus_active": active_bonuses.has("combo_multiplier"),
		"move_efficiency_active": active_bonuses.has("early_move_bonus"), 
		"queue_unlocked": is_queue_unlocked(),
		"precision_bonus_active": active_bonuses.has("precision_multiplier"),
		"current_bonuses": active_bonuses
	}
