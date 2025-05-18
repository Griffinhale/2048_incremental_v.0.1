extends Node2D

enum State { SPLASH, TITLE }

var current_state = State.SPLASH
var transition_timer := 0.0
var transition_delay := 2.5

@onready var play_button := Button.new()

func _ready():
	set_process(true)

	play_button.text = "Play"
	play_button.visible = false
	play_button.position = Vector2(500, 420)  # Adjust for center-ish
	play_button.pressed.connect(_on_play_pressed)
	add_child(play_button)

func _process(delta):
	if current_state == State.SPLASH:
		transition_timer += delta
		if transition_timer > transition_delay:
			current_state = State.TITLE
			play_button.visible = true
			queue_redraw()

func _draw():
	match current_state:
		State.SPLASH:
			# Large square in upper-left
			draw_rect(Rect2(Vector2(80, 60), Vector2(50, 50)), Color("#eee4da"))

			# Arrow pointing from top-left toward center 2x2 grid
			var arrow_tip = Vector2(230, 200)
			var arrow = [
				arrow_tip,
				arrow_tip + Vector2(-15, -5),
				arrow_tip + Vector2(-5, -15),
			]
			draw_colored_polygon(arrow, Color.WHITE)

			# Center 2x2 grid
			var center = get_viewport_rect().size / 2.0
			var tile_size = Vector2(40, 40)
			var spacing = 10
			var start_pos = center - Vector2(tile_size.x + spacing / 2, tile_size.y + spacing / 2)

			for y in range(2):
				for x in range(2):
					var offset = Vector2(x, y) * (tile_size + Vector2(spacing, spacing))
					draw_rect(Rect2(start_pos + offset, tile_size), Color("#eee4da"))

			# Bottom-centered credit
			var credit = "by philo.k"
			var font = ThemeDB.fallback_font
			var credit_width = font.get_string_size(credit).x
			var screen_width = get_viewport_rect().size.x
			var credit_pos = Vector2((screen_width - credit_width) / 2, get_viewport_rect().size.y - 40)
			draw_string(font, credit_pos, credit)

		State.TITLE:
			var title = "multiplicity."
			var font = ThemeDB.fallback_font
			var title_width = font.get_string_size(title).x
			var screen_center = get_viewport_rect().size / 2
			draw_string(font, screen_center - Vector2(title_width / 2, 100), title)

func _on_play_pressed():
	get_tree().change_scene_to_file("res://GameBoard.tscn")
