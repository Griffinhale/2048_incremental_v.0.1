extends Control

@onready var background: Panel = $Background
@onready var label: Label = $Background/ValueLabel

var value: int = 0

func _ready():
	set_value(value)

func set_value(v: int):
	value = v
	if label:
		label.text = str(v)
	update_color()

func update_color():
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

	if background:
		var stylebox := StyleBoxFlat.new()
		stylebox.bg_color = colors.get(value, Color("#ccc0b3"))
		stylebox.set_corner_radius(CORNER_TOP_LEFT, 6)
		stylebox.set_corner_radius(CORNER_TOP_RIGHT, 6)
		stylebox.set_corner_radius(CORNER_BOTTOM_LEFT, 6)
		stylebox.set_corner_radius(CORNER_BOTTOM_RIGHT, 6)
		stylebox.set_border_width_all(2)
		stylebox.border_color = Color(0.2, 0.2, 0.2)
		stylebox.set_content_margin_all(4)
		background.add_theme_stylebox_override("panel", stylebox)

	if label:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		#label.add_theme_font_size_override("font_size", 14) # adjust for queue size
