extends Node

const QUEUE_LENGTH := 5
const START_TILE_COUNT := 1

signal tile_spawned(value: int, position: Vector2)

var get_random_empty_positions: Callable = func(count): return []
var get_highest_tile_value: Callable = func(): return 1

var next_tiles: Array[int] = []

func _ready():
	reset()

func reset():
	assert(get_random_empty_positions != null, "Spawner needs get_random_empty_positions callback assigned.")
	assert(get_highest_tile_value != null, "Spawner needs get_highest_tile_value callback assigned.")

	next_tiles.clear()
	for i in QUEUE_LENGTH:
		next_tiles.append(generate_tile_value())

	var starting_positions = get_random_empty_positions.call(START_TILE_COUNT)
	for pos in starting_positions:
		var value = get_next_tile_value()
		tile_spawned.emit(value, pos)

func generate_tile_value() -> int:
	var max_tile := 1
	if get_highest_tile_value:
		max_tile = get_highest_tile_value.call()
	return get_weighted_tile_value(max_tile)

func get_weighted_tile_value(max_value: int) -> int:
	var possible_values := [1, 2]
	if max_value >= 4: possible_values.append(4)
	if max_value >= 8: possible_values.append(8)
	if max_value >= 16: possible_values.append(16)
	if max_value >= 32: possible_values.append(32)
	if max_value >= 64: possible_values.append(64)

	var weights := {
		1: 50, 2: 30, 4: 15, 8: 4, 16: 1, 32: 1, 64: 1,
	}

	var weighted_list := []
	for value in possible_values:
		for i in range(weights.get(value, 0)):
			weighted_list.append(value)

	return weighted_list[randi() % weighted_list.size()]

func get_next_tile_value() -> int:
	var val = next_tiles.pop_front()
	next_tiles.append(generate_tile_value())
	return val

func get_queue() -> Array[int]:
	return next_tiles.duplicate()

func peek_next_tile() -> int:
	return next_tiles[0] if next_tiles.size() > 0 else 1
