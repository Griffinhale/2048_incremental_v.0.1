extends Node

var total_games_played: int = 0
var games_since_last_conversion: int = 0
var all_game_stats: Array = []

var last_conversion_amount: float = 0.0
var last_converted_games: Array = []
var total_stashed_value: float = 0.0  # Preview value of current stash

var seen_tiles := {}  # Set of tile values observed this prestige

func mark_tile_seen(value: int):
	seen_tiles[value] = true

func reset_seen_tiles():
	seen_tiles.clear()

func has_seen_tile(value: int) -> bool:
	return seen_tiles.has(value)

# Track how many tiles of each value were spawned globally
var tile_spawn_counts := {}

func record_game(stats: GameStats):
	total_games_played += 1
	games_since_last_conversion += 1
	all_game_stats.append(stats)
	total_stashed_value += _convert_score_to_currency(stats)

func reset_stash():
	games_since_last_conversion = 0

func track_tile_spawn(value: int):
	tile_spawn_counts[value] = tile_spawn_counts.get(value, 0) + 1

func convert_all_stashed_games() -> float:
	var total_earned := 0.0
	var converted_games := all_game_stats.duplicate()  # Keep original stats for review

	for stats in all_game_stats:
		var earned = _convert_score_to_currency(stats)
		total_earned += earned
	
	# Track last conversion info
	last_converted_games = converted_games
	last_conversion_amount = total_earned
	
	# Add to CurrencyManager
	CurrencyManager.add_currency("conversion", total_earned)

	# Reset stash
	all_game_stats.clear()
	games_since_last_conversion = 0
	total_stashed_value = 0.0
	
	print("Converted %d games. Total earned: %.2f" % [converted_games.size(), total_earned])
	return total_earned

func _convert_score_to_currency(stats: GameStats) -> float:
	var base = stats.score * 0.01 + stats.moves * 0.05
	var bonus = stats.merge_efficiency * 5.0 + stats.combo_peak * 0.02
	var duration_bonus = stats.duration / 60.0  # 1 coin per minute
	return base + bonus + duration_bonus
	
func get_tile_frequency(tile_value: int) -> float:
	# Stub - return 0 for now
	# Later this will return actual frequency data
	return 0.0

func get_tile_usage_stats() -> Dictionary:
	# Stub - return empty for now
	# Later this will return tile merge statistics
	return {}
