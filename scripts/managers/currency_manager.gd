extends Node

# Signals for each currency type
signal currency_changed(currency_type: String, new_value: float)
signal conversion_rate_updated(new_rate: float)

# Currency storage
var currencies := {
	"score": 0.0,           # Immediate gameplay reward
	"conversion": 0.0,      # Main idle currency
	"xp": 0.0,             # Upgrade tree currency
	"prestige": 0.0,       # Reset currency
	"apex": 0.0            # Ascension currency
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
		"total_spent": total_spent.duplicate()
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
