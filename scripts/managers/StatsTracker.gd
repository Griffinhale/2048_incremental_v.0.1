extends Node

signal new_highest_tile(value: int)
signal games_converted(total_earned: float, games_count: int)


var total_games_played: int = 0
var games_since_last_conversion: int = 0
var pending_game_stats: Array = [] # change to stacked game stats
var last_converted_games: Array = []
var highest_tile_achieved: int = 1  # Start with tile 1 (2^1 = 2) as achieved
# Track how many tiles of each value were spawned globally
var tile_spawn_counts := {}
var seen_tiles := {}  # Set of tile values observed this prestige

func mark_tile_seen(value: int):
	seen_tiles[value] = true

func reset_seen_tiles():
	seen_tiles.clear()

func get_pending_games_count() -> int:
	return pending_game_stats.size()

func request_conversion_of_pending_games():
	if pending_game_stats.size() > 0:
		var total_earned = CurrencyManager.convert_multiple_games(pending_game_stats)
		
		# Update our tracking
		last_converted_games = pending_game_stats.duplicate()
		pending_game_stats.clear()
		games_since_last_conversion = 0
		
		# Emit signal for UI updates
		emit_signal("games_converted", total_earned, last_converted_games.size())

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
	

func reset_stash():
	games_since_last_conversion = 0

func track_tile_spawn(value: int):
	tile_spawn_counts[value] = tile_spawn_counts.get(value, 0) + 1


	
func get_tile_frequency(tile_value: int) -> float:
	# Stub - return 0 for now
	# Later this will return actual frequency data
	return 0.0

func get_tile_usage_stats() -> Dictionary:
	# Stub - return empty for now
	# Later this will return tile merge statistics
	return {}
