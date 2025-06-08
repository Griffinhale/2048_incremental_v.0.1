extends Node

signal new_highest_tile(value: int)
signal games_converted(total_earned: float, games_count: int)
signal xp_awarded(xp_type: String, amount: float, reason: String)  # New XP tracking signal

var total_games_played: int = 0
var games_since_last_conversion: int = 0
var pending_game_stats: Array = [] # change to stacked game stats
var last_converted_games: Array = []
var highest_tile_achieved: int = 1  # Start with tile 1 (2^1 = 2) as achieved

@onready var game_ui = "$../"
# Track how many tiles of each value were spawned globally
var tile_spawn_counts := {}
var seen_tiles := {}  # Set of tile values observed this prestige

# Current game session tracking for XP calculations
var current_game_stats: Dictionary = {
	"moves_made": 0,
	"tiles_merged": 0,
	"current_score": 0,
	"combo_peak": 0,
	"current_combo": 0,
	"merge_count": 0,
	"start_time": 0.0,
	"last_move_time": 0.0
}

# Generator activity tracking for Generator XP
var generator_activity: Dictionary = {
	"total_yield_collected": 0.0,
	"upgrades_purchased": 0,
	"upgrade_cost_total": 0.0,
	"active_generator_count": 0,
	"targeting_effectiveness_sum": 0.0,
	"yield_events_count": 0
}

# Conversion activity tracking for Conversion XP
var conversion_activity: Dictionary = {
	"total_conversions": 0,
	"total_converted_amount": 0.0,
	"largest_single_conversion": 0.0,
	"average_batch_size": 0.0,
	"conversion_efficiency_history": []
}

# Manager references
var currency_manager: CurrencyManager

func _ready():
	# Get reference to currency manager for XP distribution
	currency_manager = get_node("/root/CurrencyManager")
	if not currency_manager:
		push_error("StatsTracker: CurrencyManager not found")
	reset_current_game_stats()

## Game Session Management
func start_new_game():
	reset_current_game_stats()
	current_game_stats["start_time"] = Time.get_unix_time_from_system()

func reset_current_game_stats():
	current_game_stats = {
		"moves_made": 0,
		"tiles_merged": 0,
		"current_score": 0,
		"combo_peak": 0,
		"current_combo": 0,
		"merge_count": 0,
		"start_time": Time.get_unix_time_from_system(),
		"last_move_time": Time.get_unix_time_from_system()
	}

## Active Play XP Integration Methods
func track_move_completed(score_gained: int, tiles_merged_this_move: int):
	current_game_stats["moves_made"] += 1
	current_game_stats["tiles_merged"] += tiles_merged_this_move
	current_game_stats["current_score"] += score_gained
	current_game_stats["last_move_time"] = Time.get_unix_time_from_system()
	
	# Track combo system
	if tiles_merged_this_move > 0:
		current_game_stats["current_combo"] += score_gained
		current_game_stats["merge_count"] += 1
	else:
		# Reset combo if no merges
		current_game_stats["combo_peak"] = max(current_game_stats["combo_peak"], current_game_stats["current_combo"])
		current_game_stats["current_combo"] = 0
	
	# Calculate move efficiency for XP
	var move_efficiency = calculate_move_efficiency(score_gained, tiles_merged_this_move)
	print("move completed")
	# Award Active XP for this move
	if currency_manager:
		xp_awarded.emit({
		"type": "active",
		"context": "move", 
		"data": {
			"score_gained": score_gained,
			"tiles_merged_this_move": tiles_merged_this_move,
			"move_efficiency": move_efficiency
		}
	})

func calculate_move_efficiency(score_gained: int, tiles_merged: int) -> float:
	# Calculate efficiency based on score per tile merged
	if tiles_merged == 0:
		return 0.1  # Low efficiency for moves with no merges
	
	var base_efficiency = float(score_gained) / (tiles_merged * 10.0)  # Normalize
	
	# Bonus for consecutive merges (combo system)
	var combo_bonus = min(current_game_stats["current_combo"] / 1000.0, 2.0)  # Cap at 2x
	
	return min(base_efficiency + combo_bonus, 5.0)  # Cap total efficiency

func complete_game(final_stats: GameStats):
	# Finalize current game stats
	current_game_stats["combo_peak"] = max(current_game_stats["combo_peak"], current_game_stats["current_combo"])
	
	# Calculate efficiency metrics for XP
	var efficiency_metrics = calculate_game_efficiency_metrics(final_stats)
	
	# Award Active XP for game completion
	if currency_manager:
		var max_tile_power = log(final_stats.max_tile) / log(2) if final_stats.max_tile > 0 else 1
		var xp_awarded = currency_manager.award_active_xp_for_game_completion(
			final_stats.score, 
			final_stats.moves, 
			int(max_tile_power), 
			efficiency_metrics
		)
		emit_signal("xp_awarded", "active_xp", xp_awarded, "game_completed")
	
	# Record game as before
	record_game(final_stats)

func calculate_game_efficiency_metrics(stats: GameStats) -> Dictionary:
	var game_duration = Time.get_unix_time_from_system() - current_game_stats["start_time"]
	
	return {
		"merge_efficiency": stats.merge_efficiency,
		"combo_peak": current_game_stats["combo_peak"],
		"moves_per_minute": (stats.moves / max(game_duration / 60.0, 0.1)),
		"score_per_move": float(stats.score) / max(stats.moves, 1),
		"tiles_merged_ratio": float(current_game_stats["tiles_merged"]) / max(stats.moves, 1)
	}

## Conversion XP Integration Methods
func track_conversion_completed(converted_amount: float, games_in_batch: int):
	conversion_activity["total_conversions"] += 1
	conversion_activity["total_converted_amount"] += converted_amount
	conversion_activity["largest_single_conversion"] = max(conversion_activity["largest_single_conversion"], converted_amount)
	
	# Update average batch size
	var total_games_converted = conversion_activity["total_conversions"] * conversion_activity["average_batch_size"] + games_in_batch
	conversion_activity["average_batch_size"] = total_games_converted / (conversion_activity["total_conversions"])
	
	# Calculate conversion efficiency
	var efficiency_rating = calculate_conversion_efficiency(converted_amount, games_in_batch)
	conversion_activity["conversion_efficiency_history"].append(efficiency_rating)
	
	# Keep only last 20 efficiency ratings
	if conversion_activity["conversion_efficiency_history"].size() > 20:
		conversion_activity["conversion_efficiency_history"].pop_front()
	
	# Award Conversion XP
	if currency_manager:
		xp_awarded.emit({
		"type": "conversion",
		"context": "conversion",
		"data": {
			"converted_amount": converted_amount,
			"games_in_batch": games_in_batch,
			"efficiency_rating": efficiency_rating
		}
	})

func calculate_conversion_efficiency(converted_amount: float, games_in_batch: int) -> float:
	# Efficiency based on batch size and conversion amount
	var batch_efficiency = min(games_in_batch / 5.0, 2.0)  # Bonus for larger batches, cap at 2x
	var amount_efficiency = min(converted_amount / 50.0, 1.5)  # Bonus for larger conversions, cap at 1.5x
	
	return batch_efficiency + amount_efficiency

## Generator XP Integration Methods
func track_generator_yield(yield_amount: float, active_generators: int, targeting_effectiveness: float = 0.0):
	generator_activity["total_yield_collected"] += yield_amount
	generator_activity["active_generator_count"] = active_generators
	generator_activity["yield_events_count"] += 1
	
	# Track targeting effectiveness
	if targeting_effectiveness > 0:
		generator_activity["targeting_effectiveness_sum"] += targeting_effectiveness
	
	# Award Generator XP for yield
	if currency_manager:
		var avg_targeting = 0.0
		if generator_activity["yield_events_count"] > 0:
			avg_targeting = generator_activity["targeting_effectiveness_sum"] / generator_activity["yield_events_count"]
		
		var xp_awarded = currency_manager.award_generator_xp_for_yield(yield_amount, active_generators, targeting_effectiveness)
		emit_signal("xp_awarded", "generator_xp", xp_awarded, "generator_yield")

func track_generator_upgrade(upgrade_cost: float):
	generator_activity["upgrades_purchased"] += 1
	generator_activity["upgrade_cost_total"] += upgrade_cost
	
	# Award Generator XP for upgrade
	if currency_manager:
		var xp_awarded = currency_manager.award_generator_xp_for_upgrade(upgrade_cost)
		emit_signal("xp_awarded", "generator_xp", xp_awarded, "generator_upgrade")

## Enhanced Conversion System with XP
func request_conversion_of_pending_games():
	if pending_game_stats.size() > 0:
		var total_earned = currency_manager.convert_multiple_games(pending_game_stats)
		
		# Track conversion for XP (this will trigger XP award in convert_multiple_games)
		track_conversion_completed(total_earned, pending_game_stats.size())
		
		# Update our tracking
		last_converted_games = pending_game_stats.duplicate()
		pending_game_stats.clear()
		games_since_last_conversion = 0
		
		# Emit signal for UI updates
		emit_signal("games_converted", total_earned, last_converted_games.size())

## XP Summary and Analytics Methods
func get_current_session_xp_summary() -> Dictionary:
	return {
		"active_xp_sources": {
			"moves_made": current_game_stats["moves_made"],
			"tiles_merged": current_game_stats["tiles_merged"],
			"current_combo": current_game_stats["current_combo"],
			"combo_peak": current_game_stats["combo_peak"]
		},
		"conversion_xp_sources": {
			"conversions_completed": conversion_activity["total_conversions"],
			"total_converted": conversion_activity["total_converted_amount"],
			"average_batch_size": conversion_activity["average_batch_size"]
		},
		"generator_xp_sources": {
			"total_yield": generator_activity["total_yield_collected"],
			"upgrades_purchased": generator_activity["upgrades_purchased"],
			"upgrade_cost_total": generator_activity["upgrade_cost_total"]
		}
	}

func get_xp_earning_efficiency() -> Dictionary:
	var active_efficiency = 0.0
	if current_game_stats["moves_made"] > 0:
		active_efficiency = float(current_game_stats["current_score"]) / current_game_stats["moves_made"]
	
	var conversion_efficiency = 0.0
	if conversion_activity["conversion_efficiency_history"].size() > 0:
		var total = 0.0
		for eff in conversion_activity["conversion_efficiency_history"]:
			total += eff
		conversion_efficiency = total / conversion_activity["conversion_efficiency_history"].size()
	
	var generator_efficiency = 0.0
	if generator_activity["yield_events_count"] > 0:
		generator_efficiency = generator_activity["targeting_effectiveness_sum"] / generator_activity["yield_events_count"]
	
	return {
		"active_efficiency": active_efficiency,
		"conversion_efficiency": conversion_efficiency,
		"generator_efficiency": generator_efficiency
	}

## Existing methods (unchanged)
func mark_tile_seen(value: int):
	seen_tiles[value] = true

func reset_seen_tiles():
	seen_tiles.clear()

func get_pending_games_count() -> int:
	return pending_game_stats.size()

func track_tile_creation(tile_value: int):
	# Call this whenever a new tile is created on the board
	var tile_power = log(tile_value) / log(2)  # Convert value back to power (2^n)
	highest_tile_achieved = max(highest_tile_achieved, int(tile_power))
	
	# Also track for has_seen_tile functionality
	if not seen_tiles.has(int(tile_power)):
		seen_tiles[int(tile_power)] = true
		print("New tile discovered: %d (value: %d)" % [int(tile_power), tile_value])

func get_highest_tile_achieved() -> int:
	return highest_tile_achieved

func get_highest_tile_value() -> int:
	# Returns the actual tile value (2^n) instead of the power
	return int(pow(2, highest_tile_achieved))

# Update existing has_seen_tile to work with the new system
func has_seen_tile(tile_power: int) -> bool:
	return tile_power <= highest_tile_achieved

# For debugging
func get_unlock_info() -> Dictionary:
	return {
		"highest_tile_power": highest_tile_achieved,
		"highest_tile_value": get_highest_tile_value(),
		"seen_tiles": seen_tiles.keys()
	}

func record_game(stats: GameStats):
	total_games_played += 1
	games_since_last_conversion += 1
	pending_game_stats.append(stats)
	xp_awarded.emit({
		"type": "active",
		"context": "game_completion",
		"data": {
			"final_score": stats.score,
			"moves_made": stats.moves,
			"max_tile_power": log(stats.max_tile) / log(2),  # Convert to power of 2
			"efficiency_metrics": {
				"merge_efficiency": stats.merge_efficiency,
				"combo_peak": stats.combo_peak
			}
		}
	})
	
func reset_stash():
	games_since_last_conversion = 0

func track_tile_spawn(value: int):
	tile_spawn_counts[value] = tile_spawn_counts.get(value, 0) + 1
	
func get_tile_frequency(tile_value: int) -> float:
	# Return actual frequency data based on spawn tracking
	var total_spawns = 0
	for count in tile_spawn_counts.values():
		total_spawns += count
	
	if total_spawns == 0:
		return 0.0
	
	return float(tile_spawn_counts.get(tile_value, 0)) / total_spawns

func get_tile_usage_stats() -> Dictionary:
	var stats = {
		"total_spawns": 0,
		"spawn_distribution": {},
		"most_common_tile": 0,
		"least_common_tile": 0,
		"spawn_variety": tile_spawn_counts.size()
	}
	
	var total_spawns = 0
	var max_spawns = 0
	var min_spawns = 999999
	var most_common = 0
	var least_common = 0
	
	for tile_value in tile_spawn_counts.keys():
		var count = tile_spawn_counts[tile_value]
		total_spawns += count
		stats["spawn_distribution"][str(tile_value)] = count
		
		if count > max_spawns:
			max_spawns = count
			most_common = tile_value
		
		if count < min_spawns:
			min_spawns = count
			least_common = tile_value
	
	stats["total_spawns"] = total_spawns
	stats["most_common_tile"] = most_common
	stats["least_common_tile"] = least_common
	
	return stats

## Reset methods for prestige system
func reset_activity_tracking():
	"""Reset activity tracking for prestige while preserving permanent achievements"""
	generator_activity = {
		"total_yield_collected": 0.0,
		"upgrades_purchased": 0,
		"upgrade_cost_total": 0.0,
		"active_generator_count": 0,
		"targeting_effectiveness_sum": 0.0,
		"yield_events_count": 0
	}
	
	conversion_activity = {
		"total_conversions": 0,
		"total_converted_amount": 0.0,
		"largest_single_conversion": 0.0,
		"average_batch_size": 0.0,
		"conversion_efficiency_history": []
	}
	
	# Reset current game but preserve achievements
	reset_current_game_stats()
	
	# Clear pending games
	pending_game_stats.clear()
	last_converted_games.clear()
	games_since_last_conversion = 0

## Save/Load functionality for XP system
func save_stats_state() -> Dictionary:
	return {
		"total_games_played": total_games_played,
		"highest_tile_achieved": highest_tile_achieved,
		"seen_tiles": seen_tiles.duplicate(),
		"tile_spawn_counts": tile_spawn_counts.duplicate(),
		"generator_activity": generator_activity.duplicate(),
		"conversion_activity": conversion_activity.duplicate(),
		"current_game_stats": current_game_stats.duplicate(),
		"pending_game_stats": pending_game_stats.duplicate(),
		"version": "0.3"
	}

func load_stats_state(save_data: Dictionary):
	if save_data.has("total_games_played"):
		total_games_played = save_data["total_games_played"]
	
	if save_data.has("highest_tile_achieved"):
		highest_tile_achieved = save_data["highest_tile_achieved"]
	
	if save_data.has("seen_tiles"):
		seen_tiles = save_data["seen_tiles"].duplicate()
	
	if save_data.has("tile_spawn_counts"):
		tile_spawn_counts = save_data["tile_spawn_counts"].duplicate()
	
	if save_data.has("generator_activity"):
		generator_activity = save_data["generator_activity"].duplicate()
	
	if save_data.has("conversion_activity"):
		conversion_activity = save_data["conversion_activity"].duplicate()
	
	if save_data.has("current_game_stats"):
		current_game_stats = save_data["current_game_stats"].duplicate()
	
	if save_data.has("pending_game_stats"):
		pending_game_stats = save_data["pending_game_stats"].duplicate()

## Debug methods for XP system
func get_xp_debug_info() -> Dictionary:
	return {
		"session_summary": get_current_session_xp_summary(),
		"efficiency_ratings": get_xp_earning_efficiency(),
		"current_game_progress": current_game_stats.duplicate(),
		"activity_totals": {
			"generator": generator_activity.duplicate(),
			"conversion": conversion_activity.duplicate()
		}
	}
