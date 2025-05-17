class_name Tile
extends Node2D

@onready var color_rect: ColorRect = $ColorRect
@onready var label: Label = $ColorRect/Label

var grid_position: Vector2i

@export var value: int = 1:
	set(v):
		value = v
		if is_inside_tree():
			_update_tile()

func _ready():
	_update_tile()

func set_value(v: int) -> void:
	value = v
	if is_inside_tree():  # Ensure the node is initialized
		_update_tile()

func move_to_grid(new_grid_pos: Vector2i, cell_size: Vector2, board_origin: Vector2, animated := true) -> void:
	grid_position = new_grid_pos
	var new_pos = board_origin + Vector2(new_grid_pos) * cell_size + cell_size / 2.0
	
	if animated:
		var tween := get_tree().create_tween()
		tween.tween_property(self, "position", new_pos, 0.15)
	else:
		position = new_pos

func _update_tile():
	if label and color_rect:
		label.text = str(value)
		color_rect.color = get_color_for_value(value)

func get_color_for_value(val: int) -> Color:
	var colors = {
		1: Color("#eee4da"),
		2: Color("#ede0c8"),
		4: Color("#f2b179"),
		8: Color("#f59563"),
		16: Color("#f67c5f"),
		32: Color("#f65e3b"),
		64: Color("#edcf72"),
		128: Color("#edcc61"),
		256: Color("#edc850"),
		512: Color("#edc53f"),
		1024: Color("#edc22e"),
		2048: Color("#3c3a32"),
	}
	return colors.get(val, Color.WHITE)
