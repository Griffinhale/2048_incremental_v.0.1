extends Node

# Constants
const QUEUE_LENGTH := 3
const START_TILE_COUNT := 2

# Signals
signal tile_spawned(value: int, position: Vector2)

# Internal
var next_tiles: Array[int] = []

func _ready():
	reset()

func reset():
	assert(get_random_empty_positions, "Spawner needs get_random_empty_positions callback assigned.")

	next_tiles.clear()
	for i in QUEUE_LENGTH:
		next_tiles.append(generate_tile_value())

	# Start with two tiles placed randomly
	var starting_positions = get_random_empty_positions.call(START_TILE_COUNT)
	for pos in starting_positions:
		var value = get_next_tile_value()
		tile_spawned.emit(value, pos)

func generate_tile_value() -> int:
	# Later: Add weight/bias logic
	return 1

func get_next_tile_value() -> int:
	var val = next_tiles.pop_front()
	next_tiles.append(generate_tile_value())
	return val

func get_queue() -> Array[int]:
	return next_tiles.duplicate()

# Dummy version; board manager should override this or use its own
var get_random_empty_positions: Callable = func(count): return []
