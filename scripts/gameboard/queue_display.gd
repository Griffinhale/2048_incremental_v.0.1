extends Panel

@onready var board_canvas: Control = $"../BoardPanel/BoardContainer/BoardCanvas"
@onready var queue_tiles: HBoxContainer = $QueueBar/OnDeckTilesBackground/QueueTiles
@onready var next_tile_container: Control = $QueueBar/NextTileBackground


func _ready():
	board_canvas.queue_updated.connect(_on_queue_updated)
	update_queue_display()


func _on_queue_updated(queue: Array):
	update_queue_display()

func clear_container(container: Control):
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

func update_queue_display():
	clear_container(queue_tiles)

	var queue = board_canvas.spawner.get_queue()

	if queue.is_empty():
		return

	var next_tile = queue[0]  # what's going to spawn next
	var future_tiles = queue.slice(1)  # exclude the first (next spawn)

	var TilePreview = preload("res://scenes/components/TilePreview.tscn")

	# Show queue from newest [last] to oldest [first]
	for i in range(future_tiles.size() - 1, -1, -1):
		var value = future_tiles[i]
		var preview = TilePreview.instantiate()
		preview.set_value(value)
		queue_tiles.add_child(preview)

	# Clear and update the next tile container with one preview tile
	clear_container(next_tile_container)
	var next_preview = TilePreview.instantiate()
	next_preview.set_value(next_tile)
	next_tile_container.add_child(next_preview)
