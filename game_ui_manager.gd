extends Node

## GameUIManager.gd
# Central controller for UI transitions, overlays, and game panel states.

signal ui_state_changed(state_name: String)

@onready var top_bar_panel := $"../MarginContainer/GameBoard/TopBarPanel"
@onready var board_panel := $"../MarginContainer/GameBoard/BoardPanel"
@onready var queue_panel := $"../MarginContainer/GameBoard/QueuePanel"
@onready var game_board := $"../MarginContainer/GameBoard"
# For future transitions
var current_ui_state := "gameplay"

func _ready():
	# Optional: connect to signals here
	pass

func show_game_over(score: int, moves: int):
	current_ui_state = "game_over"
	emit_signal("ui_state_changed", current_ui_state)

	# Expand the top bar
	top_bar_panel.get_node("GameOverBox").visible = true
	top_bar_panel.get_node("GameOverBox/Scores/ScoreLabel").text = "Score: %d" % score
	top_bar_panel.get_node("GameOverBox/Scores/MovesLabel").text = "Moves: %d" % moves

	var tween := get_tree().create_tween()
	tween.tween_property(top_bar_panel, "custom_minimum_size:y", 300, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Hide lower panels
	queue_panel.visible = false
	top_bar_panel.set_stretch_ratio(2)
	board_panel.set_stretch_ratio(1.25)
func reset_to_gameplay():
	current_ui_state = "gameplay"
	emit_signal("ui_state_changed", current_ui_state)

	# Collapse top bar
	var tween := get_tree().create_tween()
	tween.tween_property(top_bar_panel, "custom_minimum_size:y", 0, 0.2)
	top_bar_panel.get_node("GameOverBox").visible = false

	# Show normal panels
	queue_panel.visible = true
	board_panel.mouse_filter = Control.MOUSE_FILTER_STOP

func transition_to(screen_name: String):
	# Placeholder: use this to switch to tutorial screens, alt modes, etc
	print("Transitioning to: ", screen_name)
	current_ui_state = screen_name
	emit_signal("ui_state_changed", current_ui_state)

	# Add visual transitions or scene loads here


func _on_board_canvas_game_over(score: int, moves: int) -> void:
	show_game_over(game_board.score, moves)
