extends Control

# === Constants and resources ===
const ROWS := 4
const COLS := 4
const TILE_SCENE := preload("res://scenes/components/Tile.tscn")

# === Board state ===
var cell_size: Vector2
var board_origin: Vector2
var tile_grid := []
var game_over_screen: Node = null
var move_count := 0
var game_start_time: float = 0.0
var merge_count: int = 0
var peak_combo_score: int = 0


var current_score := 0:
	set(value):
		current_score = value
		emit_signal("score_changed", value)

# === Signals ===
signal tile_merged(value: int)
signal queue_updated(queue: Array)
signal game_over(stats: GameStats)
signal score_changed(new_score: int)

# === Tile spawner instance ===
@onready var spawner = preload("res://scripts/managers/Spawner.gd").new()

# === Movement directions and mapped input strings ===
enum Direction {
	LEFT,
	RIGHT,
	UP,
	DOWN
}

var input_map := {
	"left": Direction.LEFT,
	"right": Direction.RIGHT,
	"up": Direction.UP,
	"down": Direction.DOWN,
}


# === Creates and animates a new tile ===
func _on_tile_spawned(value: int, pos: Vector2):
	var tile = TILE_SCENE.instantiate()
	tile.value = value
	add_child(tile)
	StatsTracker.mark_tile_seen(value)

	var grid_pos = Vector2i(pos)
	var tile_size = cell_size
	var start_size = Vector2.ZERO  # start from zero for animation

	# Set position & initial size
	tile.move_to_grid(grid_pos, cell_size, board_origin, false)
	tile.custom_minimum_size = start_size

	# Animate size
	var tween := get_tree().create_tween()
	tween.tween_property(tile, "size", cell_size * .95 , .2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(tile, "size", cell_size , .4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Register in tile grid
	tile_grid[pos.y][pos.x] = tile


# === Restarts board scene ===
func _on_restart_requested():
	get_tree().reload_current_scene()

# === Shows score list? ===
func _on_scores_requested():
	print("Scores button clicked (not implemented)")



# === Recalculate layout if screen size changes ===
func resize():
	calculate_board_geometry()
	queue_redraw()

# === Calculates board size and cell size based on screen dimensions ===
func calculate_board_geometry():
	var canvas_size = size  # Size of the BoardCanvas node
	var board_size = canvas_size * 0.95  # Use 95% of the available space (leave margin)
	var min_dim = min(board_size.x, board_size.y)
	board_size = Vector2(min_dim, min_dim)
	board_origin = (canvas_size - board_size) / 2.0
	cell_size = board_size / Vector2(COLS, ROWS)



# === Returns a shuffled list of empty cell positions ===
func get_random_empty_positions(count: int) -> Array:
	var empties := []
	for row in range(ROWS):
		for col in range(COLS):
			if tile_grid[row][col] == null:
				empties.append(Vector2i(col, row))
	empties.shuffle()
	return empties.slice(0, count)

# === Spawns a tile after a successful move, triggering queue update ===
func spawn_post_move_tile():
	var empty = get_random_empty_positions(1)
	if empty.size() > 0:
		var pos = empty[0]
		var val = spawner.get_next_tile_value()
		_on_tile_spawned(val, pos)
		queue_updated.emit(spawner.get_queue())
		StatsTracker.track_tile_creation(val)
		GeneratorManager.check_for_newly_unlocked_generators()

# === Debug helper to verify tile positions match internal grid ===
func verify_grid_consistency():
	for y in range(ROWS):
		for x in range(COLS):
			var tile = tile_grid[y][x]
			if tile != null:
				if not tile is Tile:
					print("❌ tile_grid[%d][%d] is not a Tile! Found: %s" % [y, x, tile])
				elif tile.grid_position != Vector2i(x, y):
					print("⚠️ tile at [%d][%d] has wrong grid_position: %s" % [y, x, tile.grid_position])

# === Moves and merges all tiles based on input direction ===
func shift_tiles(direction: int) -> bool:
	var moved := false
	reset_visited_flags()
	
	# Determine tile iteration order for correct pushing direction
	var x_range = range(COLS)
	var y_range = range(ROWS)
	if direction == Direction.RIGHT:
		x_range = range(COLS - 1, -1, -1)
	if direction == Direction.DOWN:
		y_range = range(ROWS - 1, -1, -1)

	for y in y_range:
		for x in x_range:
			var tile = tile_grid[y][x]
			if tile == null:
				continue

			var pos = Vector2i(x, y)
			
			# Get movement vector based on direction
			var dir
			match direction:
				Direction.LEFT: dir = Vector2i(-1, 0)
				Direction.RIGHT: dir = Vector2i(1, 0)
				Direction.UP: dir = Vector2i(0, -1)
				Direction.DOWN: dir = Vector2i(0, 1)
				_: dir = Vector2i.ZERO

			var next_pos = pos + dir
			while is_within_bounds(next_pos):
				var next_tile = tile_grid[next_pos.y][next_pos.x]
				if next_tile == null:
					# Move tile into empty space
					tile_grid[next_pos.y][next_pos.x] = tile
					tile_grid[pos.y][pos.x] = null
					tile.move_to_grid(next_pos, cell_size, board_origin)
					pos = next_pos
					next_pos += dir
					moved = true
				elif not next_tile.visited and not tile.visited and next_tile.value == tile.value:
					# Merge same value tiles
					next_tile.value *= 2
					var merged_value = next_tile.value
					next_tile.visited = true
					merge_count += 1
					current_score += merged_value
					if merge_count > peak_combo_score:
						peak_combo_score = merge_count
					tile.queue_free()
					tile_grid[pos.y][pos.x] = null
					moved = true
					break
				else:
					# Stop if blocked by a different tile
					break

	return moved

# === Checks if position is on the board ===
func is_within_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < COLS and pos.y >= 0 and pos.y < ROWS

# === Clears the visited flag for all tiles at the start of a turn ===
func reset_visited_flags():
	for row in tile_grid:
		for tile in row:
			if tile:
				tile.visited = false

func _get_minimum_size() -> Vector2:
	return Vector2(600, 600)  # or based on tile count/size

# === Checks if board has reached unplayable state ===
func check_game_over() -> bool:
	# If there are any empty cells, not game over
	for row in tile_grid:
		for tile in row:
			if tile == null:
				return false

	# If any tile has a matching neighbor, still playable
	for y in range(ROWS):
		for x in range(COLS):
			var tile = tile_grid[y][x]
			if tile == null:
				continue
			for offset in [Vector2i(1, 0), Vector2i(0, 1)]:
				var nx = x + offset.x
				var ny = y + offset.y
				if nx < COLS and ny < ROWS:
					var neighbor = tile_grid[ny][nx]
					if neighbor and neighbor.value == tile.value:
						return false
	return true

# === helper function used in spawner logic ===
func get_highest_tile_value() -> int:
	var highest := 1
	for row in tile_grid:
		for tile in row:
			if tile and tile.value > highest:
				highest = tile.value
	return highest

# === Trigger switch to game over view ===
func trigger_game_over():
	var duration = Time.get_ticks_msec() / 1000.0 - game_start_time
	var stats = GameStats.new()
	stats.score = current_score
	stats.moves = move_count
	stats.duration = duration
	stats.max_tile = get_highest_tile_value()
	stats.merges = merge_count
	stats.combo_peak = peak_combo_score
	stats.merge_efficiency = merge_count / float(move_count)
	emit_signal("game_over", stats)
	# Optionally: calculate empty cell ratio
	#var empty_count = 0
	#for row in tile_grid:
		#for tile in row:
			#if tile == null:
				#empty_count += 1
	#stats.empty_cell_ratio = float(empty_count) / (ROWS * COLS)

	


	#game_over_screen = GAME_OVER_SCENE.instantiate()
	#add_child(game_over_screen)
	#game_over_screen.set_final_stats(current_score, move_count)
	#game_over_screen.restart_requested.connect(_on_restart_requested)
	#game_over_screen.scores_requested.connect(_on_scores_requested)
func reset_board():
	# Clear all child tiles
	for row in tile_grid:
		for tile in row:
			if tile != null:
				tile.queue_free()
				tile = null

	# Reset grid structure
	tile_grid.clear()
	for y in range(ROWS):
		tile_grid.append([])
		for x in range(COLS):
			tile_grid[y].append(null)

	# Reset state
	move_count = 0
	current_score = 0

	# Reset spawner and spawn initial tiles
	spawner.reset()
	queue_updated.emit(spawner.get_queue())
	queue_redraw()
	print("Board reset complete")


func _ready():
	connect("resized", Callable(self, "calculate_board_geometry"))
	calculate_board_geometry()
	game_start_time = Time.get_ticks_msec() / 1000.0
	get_tree().get_root().size_changed.connect(resize)

	# Initialize empty grid with nulls
	for row in range(ROWS):
		tile_grid.append([])
		for col in range(COLS):
			tile_grid[row].append(null)

	# Set up tile spawner with empty position callback for initial spawn
	spawner.get_random_empty_positions = get_random_empty_positions
	spawner.get_highest_tile_value = get_highest_tile_value  # 👈 hook this up

	spawner.tile_spawned.connect(_on_tile_spawned)
	add_child(spawner)
	spawner.reset()

func _draw():
	for row in range(ROWS):
		for col in range(COLS):
			var top_left = board_origin + Vector2(col, row) * cell_size
			draw_rect(Rect2(top_left, cell_size), Color.DARK_SLATE_GRAY, true)
			draw_rect(Rect2(top_left, cell_size), Color.BLACK, false)

func _unhandled_input(event: InputEvent):
	# Only process key press events, not mouse clicks or other inputs
	if not event is InputEventKey:
		return
	
	# Only process when the key is first pressed (not held or released)
	if not event.pressed:
		return
	
	# Check for specific UI directional inputs
	var direction = null
	if Input.is_action_just_pressed("ui_left"):
		direction = Direction.LEFT
	elif Input.is_action_just_pressed("ui_right"):
		direction = Direction.RIGHT
	elif Input.is_action_just_pressed("ui_up"):
		direction = Direction.UP
	elif Input.is_action_just_pressed("ui_down"):
		direction = Direction.DOWN
	
	# If we got a valid direction, process the move
	if direction != null:
		if shift_tiles(direction):
			move_count += 1
			spawn_post_move_tile()
			verify_grid_consistency()
			if check_game_over():
				trigger_game_over()
