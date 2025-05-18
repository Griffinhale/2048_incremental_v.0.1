class_name Tile
extends Control

@onready var background: Panel = $Panel
@onready var label: Label = $Panel/Label

var grid_position: Vector2i
var visited: bool = false  # "visited" flag to prevent double merging

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
	var new_pos = board_origin + Vector2(new_grid_pos) * cell_size


	if animated:
		var tween := get_tree().create_tween()
		tween.tween_property(self, "position", new_pos, 0.15)
	else:
		position = new_pos
	
	size = cell_size

func _update_tile():
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
	if label and background:
		label.text = str(value)
		var stylebox := StyleBoxFlat.new()
		stylebox.bg_color = colors.get(value, Color("#ccc0b3"))
		stylebox.set_corner_radius(CORNER_TOP_LEFT, 6)
		stylebox.set_corner_radius(CORNER_TOP_RIGHT, 6)
		stylebox.set_corner_radius(CORNER_BOTTOM_LEFT, 6)
		stylebox.set_corner_radius(CORNER_BOTTOM_RIGHT, 6)
		stylebox.set_border_width_all(2)
		stylebox.border_color = Color(0.2, 0.2, 0.2)
	#stylebox.set_content_margin_all(4)
		background.add_theme_stylebox_override("panel", stylebox)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		#label.add_theme_font_size_override("font_size", 14) # adjust for queue size

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

# Resets the visited flag after each turn
func reset_visited():
	visited = false
