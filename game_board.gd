extends Node2D
## 
# General game board logic: Notice input, determine whether affecting rows or columns (L/R v U/D)
# 
##
const ROWS := 4
const COLS := 4
const TILE_SCENE := preload("res://Tile.tscn")

var cell_size: Vector2
var board_origin: Vector2
var tile_grid := []

@onready var spawner = preload("res://Spawner.gd").new()

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

func _ready():
	calculate_board_geometry()
	get_tree().get_root().size_changed.connect(resize)
	spawner.get_random_empty_positions = get_random_empty_positions
	# Init tile grid
	for row in ROWS:
		tile_grid.append([])
		for col in COLS:
			tile_grid[row].append(null)

	# Connect to spawner signal
	spawner.tile_spawned.connect(_on_tile_spawned)
	add_child(spawner)
	spawner.reset()

func resize():
	calculate_board_geometry()
	queue_redraw()
	# Optional: reposition existing tiles here

func calculate_board_geometry():
	var screen_size = get_viewport_rect().size
	var board_size = screen_size * 0.8
	board_origin = (screen_size - board_size) / 2.0
	cell_size = board_size / Vector2(COLS, ROWS)

func _unhandled_input(event: InputEvent):
	if event.is_pressed():
		var dir = input_map.get(event.as_text_key_label().to_lower(), null)
		#print(event.as_text_key_label().to_lower())
		if dir != null:
			#print(dir)
			if shift_tiles(dir):
				spawn_post_move_tile()
				verify_grid_consistency()

func _draw():
	for row in ROWS:
		for col in COLS:
			var top_left = board_origin + Vector2(col, row) * cell_size
			draw_rect(Rect2(top_left, cell_size), Color.DARK_SLATE_GRAY, true)
			draw_rect(Rect2(top_left, cell_size), Color.BLACK, false)

func _on_tile_spawned(value: int, pos: Vector2):
	var tile = TILE_SCENE.instantiate()
	tile.value = value
	add_child(tile)
	debug_print_board()

	tile.move_to_grid(pos, cell_size, board_origin, false)# center in cell
	tile.scale = Vector2.ZERO
	var tween := get_tree().create_tween()
	tween.tween_property(tile, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	tile_grid[pos.y][pos.x] = tile

func get_cell_screen_position(grid_pos: Vector2i) -> Vector2:
	return board_origin + Vector2(grid_pos.x, grid_pos.y) * cell_size

func get_random_empty_positions(count: int) -> Array:
	var empties := []
	for row in ROWS:
		for col in COLS:
			if tile_grid[row][col] == null:
				empties.append(Vector2i(col, row))
	empties.shuffle()
	return empties.slice(0, count)

func debug_print_line(line: Array):
	print(line)
	
func debug_print_board():
	for row in tile_grid:
		var row_str = []
		for t in row:
			if t == null:
				row_str.append(".")
			elif t is Tile:
				row_str.append(str(t.value))
			else:
				row_str.append("[Invalid:" + str(t.get_class())+"]")
		print(row_str)
	print("Turn over.")
	
# For moving all tiles one direction
func shift_tiles(dir: int) -> bool:
	var moved := false

	match dir:
		Direction.LEFT:
			for row_idx in range(ROWS):
				print(row_idx)
				var row = tile_grid[row_idx]
				moved = shift_line(row, true, row_idx) or moved

		Direction.RIGHT:
			for row_idx in range(ROWS):
				print(row_idx)
				var row = tile_grid[row_idx].duplicate()
				row.reverse()
				moved = shift_line(row, true, row_idx) or moved
				row.reverse()
				for col in range(COLS):	
					tile_grid[row_idx][col] = row[col]

		Direction.UP:
			for col in range(COLS):
				var column := []
				for row in range(ROWS):
					column.append(tile_grid[row][col])
				moved = shift_line(column, false, col) or moved
				for row in range(ROWS):
					tile_grid[row][col] = column[row]

		Direction.DOWN:
			for col in range(COLS):
				var column := []
				for row in range(ROWS):
					column.append(tile_grid[ROWS - 1 - row][col])
				moved = shift_line(column, false, col) or moved
				for row in range(ROWS):
					tile_grid[ROWS - 1 - row][col] = column[row]

	return moved

# handles each line individually, handling merges
func shift_line(line: Array, is_row: bool, index: int) -> bool:
	var original_values := line.map(func(t): return t.value if t else null)
	var new_line: Array = []
	var skip := false
	var moved := false

	for i in range(line.size()):
		if skip:
			skip = false
			continue

		var current = line[i]
		if current == null:
			continue

		var j = i + 1
		while j < line.size() and line[j] == null:
			j += 1

		if j < line.size() and line[j] != null and line[j].value == current.value:
			current.value *= 2
			line[j].queue_free()
			line[j] = null
			new_line.append(current)
			skip = true
			moved = true
		else:
			new_line.append(current)
	# fill new line with nulls for board parity
	while new_line.size() < line.size():
		new_line.append(null)
	
	# overwrite original line
	for i in range(line.size()):
		var tile: Tile = new_line[i]
		line[i] = tile
		if line[i]:
			var grid_pos = Vector2i(i, index) if is_row else Vector2i(index, i)
			line[i].move_to_grid(grid_pos, cell_size, board_origin)
			tile_grid[grid_pos.y][grid_pos.x] = tile
			
	#debug_print_line(line)
	# Re-check if any movement actually happened
	var new_values := line.map(func(t): return t.value if t else null)
	return moved or (original_values != new_values)

# Add next tile in queue
func spawn_post_move_tile():
	var empty = get_random_empty_positions(1)
	if empty.size() > 0:
		var pos = empty[0]
		var val = spawner.get_next_tile_value()
		_on_tile_spawned(val, pos)


func verify_grid_consistency():
	for y in range(ROWS):
		for x in range(COLS):
			var tile = tile_grid[y][x]
			if tile != null:
				if not tile is Tile:
					print("❌ tile_grid[%d][%d] is not a Tile! Found: %s" % [y, x, tile])
				elif tile.grid_position != Vector2i(x, y):
					print("⚠️ tile at [%d][%d] has wrong grid_position: %s" % [y, x, tile.grid_position])


#game over check
