extends Node

# Signals for each currency type
signal currency_changed(currency_type: String, new_value: float)
signal conversion_rate_updated(new_rate: float)
signal xp_gained(xp_type: String, amount: float)  # New signal for XP events

# Currency storage - Enhanced with XP currencies
var currencies := {
	"score": 0.0,           # Immediate gameplay reward
	"conversion": 0.0,      # Main idle currency
	"prestige": 0.0,       # Reset currency
	"apex": 0.0,           # Ascension currency
	# XP currencies for upgrade trees
	"active_xp": 0.0,      # Active Play tree XP
	"conversion_xp": 0.0,  # Conversion tree XP
	"generator_xp": 0.0,   # Generator tree XP
	"discipline_xp": 0.0,  # Challenge/Discipline tree XP (future)
	"reset_xp": 0.0,       # Reset tree XP (future)
	"lore_xp": 0.0         # Lore tree XP (future)
}

# XP earning configuration
var xp_config := {
	"active_xp": {
		"base_per_move": 1.0,
		"base_per_merge": 2.0,
		"game_completion_base": 10.0,
		"efficiency_bonus_multiplier": 0.5,
		"combo_bonus_multiplier": 0.1
	},
	"conversion_xp": {
		"base_per_conversion": 5.0,
		"batch_bonus_per_game": 2.0,
		"efficiency_bonus_multiplier": 0.2,
		"large_conversion_threshold": 100.0,
		"large_conversion_bonus": 1.5
	},
	"generator_xp": {
		"base_per_yield": 0.5,
		"upgrade_xp_per_cost": 0.1,
		"targeting_effectiveness_multiplier": 0.3,
		"collection_bonus_multiplier": 0.2
	}
}

# Conversion mechanics
var conversion_rate := 1.0
var conversion_efficiency := 1.0
var last_conversion_amount: float = 0.0
var score_accumulator := 0.0  # Tracks unconverted score

# Debug tracking
var debug_enabled := true
var currency_history := {}
var total_earned := {}
var total_spent := {}

func _ready():
	initialize_debug_tracking()
	load_saved_currencies()

func initialize_debug_tracking():
	for currency_type in currencies.keys():
		currency_history[currency_type] = []
		total_earned[currency_type] = 0.0
		total_spent[currency_type] = 0.0

func add_currency(currency_type: String, amount: float) -> void:
	if not currencies.has(currency_type):
		print("Warning: Unknown currency type: %s" % currency_type)
		return
	
	if amount <= 0:
		return
	
	currencies[currency_type] += amount
	
	# Debug tracking
	if debug_enabled:
		total_earned[currency_type] += amount
		track_currency_change(currency_type, amount, "earned")
	
	# Emit specific XP signal for XP currencies
	if currency_type.ends_with("_xp"):
		emit_signal("xp_gained", currency_type, amount)
	
	emit_signal("currency_changed", currency_type, currencies[currency_type])

func spend_currency(currency_type: String, amount: float) -> bool:
	if not currencies.has(currency_type):
		print("Warning: Unknown currency type: %s" % currency_type)
		return false
	
	if currencies[currency_type] >= amount:
		currencies[currency_type] -= amount
		
		# Debug tracking
		if debug_enabled:
			total_spent[currency_type] += amount
			track_currency_change(currency_type, -amount, "spent")
		
		emit_signal("currency_changed", currency_type, currencies[currency_type])
		return true
	
	return false

func get_currency(currency_type: String) -> float:
	return currencies.get(currency_type, 0.0)

func get_all_currencies() -> Dictionary:
	return currencies.duplicate()

## XP Earning Methods - Core XP distribution system
func award_active_xp_for_move(score_gained: int, tiles_merged: int, move_efficiency: float = 1.0) -> float:
	var config = xp_config["active_xp"]
	var base_xp = config["base_per_move"] + (tiles_merged * config["base_per_merge"])
	var efficiency_bonus = move_efficiency * config["efficiency_bonus_multiplier"]
	var total_xp = base_xp + efficiency_bonus
	
	add_currency("active_xp", total_xp)
	return total_xp

func award_active_xp_for_game_completion(final_score: int, moves_made: int, max_tile_power: int, efficiency_metrics: Dictionary = {}) -> float:
	var config = xp_config["active_xp"]
	var base_xp = config["game_completion_base"]
	
	# Scale with game performance
	var score_bonus = (final_score / 1000.0) * 2.0  # 2 XP per 1000 score
	var tile_bonus = max_tile_power * 3.0  # 3 XP per tile power level
	
	# Efficiency bonuses
	var efficiency_bonus = 0.0
	if efficiency_metrics.has("merge_efficiency"):
		efficiency_bonus += efficiency_metrics["merge_efficiency"] * config["efficiency_bonus_multiplier"] * 10.0
	if efficiency_metrics.has("combo_peak"):
		efficiency_bonus += efficiency_metrics["combo_peak"] * config["combo_bonus_multiplier"]
	
	var total_xp = base_xp + score_bonus + tile_bonus + efficiency_bonus
	
	add_currency("active_xp", total_xp)
	return total_xp

func award_conversion_xp(converted_amount: float, games_in_batch: int = 1, conversion_efficiency_rating: float = 1.0) -> float:
	var config = xp_config["conversion_xp"]
	var base_xp = config["base_per_conversion"]
	
	# Scale with conversion amount
	var amount_bonus = (converted_amount / 10.0) * 1.0  # 1 XP per 10 conversion currency
	
	# Batch bonus
	var batch_bonus = max(0, games_in_batch - 1) * config["batch_bonus_per_game"]
	
	# Large conversion bonus
	var large_bonus = 0.0
	if converted_amount >= config["large_conversion_threshold"]:
		large_bonus = base_xp * config["large_conversion_bonus"]
	
	# Efficiency bonus
	var efficiency_bonus = conversion_efficiency_rating * config["efficiency_bonus_multiplier"] * converted_amount
	
	var total_xp = base_xp + amount_bonus + batch_bonus + large_bonus + efficiency_bonus
	
	add_currency("conversion_xp", total_xp)
	return total_xp

func award_generator_xp_for_yield(yield_amount: float, active_generators: int, targeting_effectiveness: float = 0.0) -> float:
	var config = xp_config["generator_xp"]
	var base_xp = yield_amount * config["base_per_yield"]
	
	# Collection bonus (more generators = more XP)
	var collection_bonus = (active_generators - 1) * config["collection_bonus_multiplier"] * yield_amount
	
	# Targeting effectiveness bonus
	var targeting_bonus = targeting_effectiveness * config["targeting_effectiveness_multiplier"] * yield_amount
	
	var total_xp = base_xp + collection_bonus + targeting_bonus
	
	add_currency("generator_xp", total_xp)
	return total_xp

func award_generator_xp_for_upgrade(upgrade_cost: float) -> float:
	var config = xp_config["generator_xp"]
	var xp_amount = upgrade_cost * config["upgrade_xp_per_cost"]
	
	add_currency("generator_xp", xp_amount)
	return xp_amount

## XP Configuration Methods
func get_xp_config() -> Dictionary:
	return xp_config.duplicate()

func update_xp_config(xp_type: String, new_config: Dictionary) -> void:
	if xp_config.has(xp_type):
		for key in new_config.keys():
			if xp_config[xp_type].has(key):
				xp_config[xp_type][key] = new_config[key]

func get_xp_currencies() -> Dictionary:
	var xp_currencies = {}
	for currency_type in currencies.keys():
		if currency_type.ends_with("_xp"):
			xp_currencies[currency_type] = currencies[currency_type]
	return xp_currencies

## Enhanced XP Debug Methods
func get_xp_debug_info() -> Dictionary:
	var xp_info = {}
	var xp_currencies = get_xp_currencies()
	
	for xp_type in xp_currencies.keys():
		xp_info[xp_type] = {
			"current_balance": xp_currencies[xp_type],
			"total_earned": total_earned.get(xp_type, 0.0),
			"earning_rate": _calculate_recent_earning_rate(xp_type),
			"config": xp_config.get(xp_type.replace("_xp", "_xp"), {})
		}
	
	return xp_info

func _calculate_recent_earning_rate(currency_type: String) -> float:
	var recent_history = currency_history.get(currency_type, [])
	var recent_earned = 0.0
	var current_time = Time.get_unix_time_from_system()
	
	# Calculate last 60 seconds of XP earning
	for entry in recent_history:
		if current_time - entry.timestamp <= 60.0 and entry.amount > 0:
			recent_earned += entry.amount
	
	return recent_earned  # XP per minute

# Conversion system - converts score to conversion currency
func convert_score_to_currency(score_amount: float) -> float:
	if score_amount <= 0:
		return 0.0
	
	# Check if we have enough score
	if not spend_currency("score", score_amount):
		return 0.0
	
	# Calculate conversion with efficiency
	var converted_amount = score_amount * conversion_rate * conversion_efficiency
	add_currency("conversion", converted_amount)
	
	return converted_amount

# Add to CurrencyManager
func convert_game_stats_to_currency(stats: GameStats) -> float:
	var base = stats.score * 0.01 + stats.moves * 0.05
	var bonus = stats.merge_efficiency * 5.0 + stats.combo_peak * 0.02
	var duration_bonus = stats.duration / 60.0
	var total_earned = base + bonus + duration_bonus
	
	# Add the currency through our existing system
	add_currency("conversion", total_earned)
	
	# Track this conversion for debug/stats
	if debug_enabled:
		track_currency_change("conversion", total_earned, "game_conversion")
	
	return total_earned

func convert_multiple_games(game_stats_array: Array) -> float:
	var total_earned := 0.0
	
	for stats in game_stats_array:
		total_earned += convert_game_stats_to_currency(stats)
	
	# Award conversion XP for batch conversion
	var games_count = game_stats_array.size()
	if games_count > 0:
		# Calculate average efficiency for XP calculation
		var total_efficiency = 0.0
		for stats in game_stats_array:
			total_efficiency += stats.merge_efficiency if stats.has_method("merge_efficiency") else 1.0
		var avg_efficiency = total_efficiency / games_count
		
		award_conversion_xp(total_earned, games_count, avg_efficiency)
	
	return total_earned

func auto_convert_score(threshold: float = 100.0) -> bool:
	var current_score = get_currency("score")
	if current_score >= threshold:
		return convert_score_to_currency(current_score) > 0
	return false

# Conversion rate management
func update_conversion_rate(new_rate: float):
	conversion_rate = max(0.1, new_rate)  # Minimum rate protection
	emit_signal("conversion_rate_updated", conversion_rate)

func update_conversion_efficiency(multiplier: float):
	conversion_efficiency = max(0.1, multiplier)

func get_conversion_rate() -> float:
	return conversion_rate

func get_conversion_efficiency() -> float:
	return conversion_efficiency

# Debug functions
func track_currency_change(currency_type: String, amount: float, action: String):
	if not debug_enabled:
		return
	
	var timestamp = Time.get_unix_time_from_system()
	var entry = {
		"timestamp": timestamp,
		"amount": amount,
		"action": action,
		"balance_after": currencies[currency_type]
	}
	
	currency_history[currency_type].append(entry)
	
	# Keep only last 100 entries per currency
	if currency_history[currency_type].size() > 100:
		currency_history[currency_type].pop_front()

func get_currency_debug_info(currency_type: String) -> Dictionary:
	if not currencies.has(currency_type):
		return {}
	
	var recent_history = currency_history.get(currency_type, [])
	var recent_earned = 0.0
	var recent_spent = 0.0
	var current_time = Time.get_unix_time_from_system()
	
	# Calculate last 60 seconds of activity
	for entry in recent_history:
		if current_time - entry.timestamp <= 60.0:
			if entry.amount > 0:
				recent_earned += entry.amount
			else:
				recent_spent += abs(entry.amount)
	
	return {
		"current_balance": currencies[currency_type],
		"total_earned": total_earned.get(currency_type, 0.0),
		"total_spent": total_spent.get(currency_type, 0.0),
		"recent_earned_per_minute": recent_earned,
		"recent_spent_per_minute": recent_spent,
		"net_recent": recent_earned - recent_spent,
		"history_entries": recent_history.size()
	}

func get_all_debug_info() -> Dictionary:
	var debug_info = {}
	for currency_type in currencies.keys():
		debug_info[currency_type] = get_currency_debug_info(currency_type)
	
	debug_info["conversion_rate"] = conversion_rate
	debug_info["conversion_efficiency"] = conversion_efficiency
	debug_info["xp_debug"] = get_xp_debug_info()
	
	return debug_info

func reset_debug_tracking():
	initialize_debug_tracking()

func set_debug_enabled(enabled: bool):
	debug_enabled = enabled

# Save/Load functionality
func save_currencies() -> Dictionary:
	return {
		"currencies": currencies.duplicate(),
		"conversion_rate": conversion_rate,
		"conversion_efficiency": conversion_efficiency,
		"total_earned": total_earned.duplicate(),
		"total_spent": total_spent.duplicate(),
		"xp_config": xp_config.duplicate()
	}

func load_saved_currencies():
	# Placeholder for actual save/load implementation
	# In v0.2, you might load from a JSON file or Godot's built-in save system
	pass

# Utility functions
func format_currency(amount: float) -> String:
	if amount >= 1000000000:
		return "%.2fB" % (amount / 1000000000.0)
	elif amount >= 1000000:
		return "%.2fM" % (amount / 1000000.0)
	elif amount >= 1000:
		return "%.2fK" % (amount / 1000.0)
	else:
		return "%.2f" % amount

func can_afford(currency_type: String, amount: float) -> bool:
	return get_currency(currency_type) >= amount

# Batch operations
func spend_multiple(costs: Dictionary) -> bool:
	# Check if we can afford all costs first
	for currency_type in costs:
		if not can_afford(currency_type, costs[currency_type]):
			return false
	
	# If we can afford everything, spend it all
	for currency_type in costs:
		spend_currency(currency_type, costs[currency_type])
	
	return true
