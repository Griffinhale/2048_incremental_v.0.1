extends Control

signal restart_requested
signal scores_requested

var final_score := 0
var move_count := 0

@onready var play_button := Button.new()
@onready var scores_button := Button.new()

# === Godot hooks ===
func _ready():
	set_process(true)

	# Play Again Button
	play_button.text = "play again"
	play_button.position = Vector2(390, 420)
	play_button.pressed.connect(_on_play_pressed)
	add_child(play_button)

	# Scores Button
	scores_button.text = "scores"
	scores_button.position = Vector2(540, 420)
	scores_button.pressed.connect(_on_scores_pressed)
	add_child(scores_button)

func _draw():
	var screen_size = get_viewport_rect().size
	var panel_size = Vector2(400, 300)
	var panel_pos = (screen_size - panel_size) / 2

	# Panel background
	draw_rect(Rect2(panel_pos, panel_size), Color(0.1, 0.1, 0.1, 0.9), true)

	var font = ThemeDB.fallback_font

	# Title
	var title_text = "Nice job."
	var title_size = font.get_string_size(title_text)
	draw_string(font, panel_pos + Vector2((panel_size.x - title_size.x) / 2, 60), title_text)

	# Score
	var score_label = "score:"
	draw_string(font, panel_pos + Vector2(100, 110), score_label)
	draw_string(font, panel_pos + Vector2(250, 110), str(final_score))

	# Moves
	draw_string(font, panel_pos + Vector2(100, 160), "moves:")
	draw_string(font, panel_pos + Vector2(250, 160), str(move_count))

# === Signal handlers ===
func _on_play_pressed():
	restart_requested.emit()

func _on_scores_pressed():
	scores_requested.emit()

func set_final_stats(score: int, moves: int):
	final_score = score
	move_count = moves
	queue_redraw()
