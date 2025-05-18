extends Node

signal ui_state_changed(state_name: String)

enum Screen {
	GAME,
	IDLE
}

var current_screen: Screen = Screen.GAME
var current_ui_state := "gameplay"

@onready var game_board := $"../GameMargins/GameBoard"
@onready var idle_panel := $"../IdleMargins/GeneratorPanel"
@onready var idle_margins := $"../IdleMargins"
@onready var to_idle_button := $"../GameMargins/GameBoard/TopBarPanel/GameOverBox/Buttons/IdleScreenSwap"
@onready var play_again_button := $"../GameMargins/GameBoard/TopBarPanel/GameOverBox/Buttons/Restart"
@onready var top_bar_panel := $"../GameMargins/GameBoard/TopBarPanel"
@onready var board_panel := $"../GameMargins/GameBoard/BoardPanel"
@onready var queue_panel := $"../GameMargins/GameBoard/QueuePanel"
@onready var board_canvas := $"../GameMargins/GameBoard/BoardPanel/BoardContainer/BoardCanvas"


func _ready():
	show_game_screen()
	print("Restart Button Found:", play_again_button)
	print("Restart Button Visible:", play_again_button.visible)
	print("Restart Mouse Filter:", play_again_button.mouse_filter)

	to_idle_button.pressed.connect(show_idle_screen)
	board_canvas.game_over.connect(_on_board_canvas_game_over)
	play_again_button.pressed.connect(_on_play_again_pressed)

func _input(event):
	if event.is_action_pressed("swap_screen"):
		swap_screen()

func show_game_screen():
	game_board.visible = true
	idle_panel.visible = false
	idle_margins.visible = false
	current_screen = Screen.GAME

func show_idle_screen():
	game_board.visible = false
	idle_margins.visible = true
	idle_panel.visible = true
	current_screen = Screen.IDLE

func swap_screen():
	if current_screen == Screen.GAME:
		show_idle_screen()
	else:
		show_game_screen()

func _on_play_again_pressed():
	reset_to_gameplay()
	board_canvas.reset_board()

func show_game_over(score: int, moves: int):
	current_ui_state = "game_over"
	emit_signal("ui_state_changed", current_ui_state)
	print("Idle Panel Visible:", idle_panel.visible)

	top_bar_panel.get_node("GameOverBox").visible = true
	top_bar_panel.get_node("GameOverBox/Scores/ScoreLabel").text = "Score: %d" % score
	top_bar_panel.get_node("GameOverBox/Scores/MovesLabel").text = "Moves: %d" % moves

	var earned_currency = convert_score_to_currency(score, moves)
	CurrencyManager.add_currency(earned_currency)
	print("Gained %.2f currency from game session" % earned_currency)

	var tween := get_tree().create_tween()
	tween.tween_property(top_bar_panel, "custom_minimum_size:y", 300, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	board_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	queue_panel.visible = false
	top_bar_panel.get_node("TopBar").visible = false
	top_bar_panel.set_stretch_ratio(2)
	board_panel.set_stretch_ratio(1.25)

func reset_to_gameplay():
	current_ui_state = "gameplay"
	emit_signal("ui_state_changed", current_ui_state)
	board_panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var tween := get_tree().create_tween()
	tween.tween_property(top_bar_panel, "custom_minimum_size:y", 0, 0.2)
	top_bar_panel.get_node("GameOverBox").visible = false
	top_bar_panel.get_node("TopBar").visible = true
	top_bar_panel.set_stretch_ratio(1)
	board_panel.set_stretch_ratio(4)
	queue_panel.visible = true

func transition_to(screen_name: String):
	print("Transitioning to: ", screen_name)
	current_ui_state = screen_name
	emit_signal("ui_state_changed", current_ui_state)

func convert_score_to_currency(score: int, moves: int) -> float:
	return score * 0.01 + moves * 0.05

func _on_board_canvas_game_over(score: int, moves: int) -> void:
	show_game_over(score, moves)
