extends Node

signal ui_state_changed(state_name: String)

enum Screen {
	GAME,
	IDLE,
	
}

var current_screen: Screen = Screen.GAME
var current_ui_state := "gameplay"
var showing_upgrades := false

@onready var game_board := $"../GameMargins/GameBoard"
@onready var idle_panel := $"../IdleMargins/GeneratorPanel"
@onready var upgrade_margins := $"../UpgradesMargins"
@onready var upgrade_panel := $"../UpgradesMargins/UpgradesPanel"
@onready var idle_margins := $"../IdleMargins"
@onready var to_idle_button := $"../GameMargins/GameBoard/TopBarPanel/GameOverBox/Buttons/IdleScreenSwap"
@onready var play_again_button := $"../GameMargins/GameBoard/TopBarPanel/GameOverBox/Buttons/Restart"
@onready var convert_and_stash := $"../GameMargins/GameBoard/TopBarPanel/GameOverBox/Buttons/ConvertAndStash"
@onready var top_bar_panel := $"../GameMargins/GameBoard/TopBarPanel"
@onready var score_label := $"../GameMargins/GameBoard/TopBarPanel/TopBar/ScoreValue"
@onready var board_panel := $"../GameMargins/GameBoard/BoardPanel"
@onready var queue_panel := $"../GameMargins/GameBoard/QueuePanel"
@onready var board_canvas := $"../GameMargins/GameBoard/BoardPanel/BoardContainer/BoardCanvas"
@onready var current_score: int = 0

func _ready():
	show_game_screen()
	print("Restart Button Found:", play_again_button)
	print("Restart Button Visible:", play_again_button.visible)
	print("Restart Mouse Filter:", play_again_button.mouse_filter)

	to_idle_button.pressed.connect(show_idle_screen)
	if not board_canvas.is_connected("game_over", _on_board_canvas_game_over):
		board_canvas.game_over.connect(_on_board_canvas_game_over)
	board_canvas.score_changed.connect(_on_current_score_changed)
	play_again_button.pressed.connect(_on_play_again_pressed)
	convert_and_stash.pressed.connect(_on_convert_stash_pressed)

func _on_convert_stash_pressed():
	var earned := StatsTracker.convert_all_stashed_games()
	print("Conversion complete.")
	top_bar_panel.get_node("GameOverBox/Label").text = "Conversion Complete."
	top_bar_panel.get_node("GameOverBox/Scores/MovesLabel").text = "Moves: 0"
	top_bar_panel.get_node("GameOverBox/Scores/ScoreLabel").text = "Score: 0"
	convert_and_stash.disabled = true
	
	
func _on_current_score_changed(value: int):
	current_score = value
	score_label.text = str(current_score)
	
func _input(event):
	if event.is_action_pressed("swap_screen"):
		swap_screen()
	if event.is_action_pressed("show_upgrades"):
		toggle_upgrades()
		
func toggle_upgrades():
	showing_upgrades = !showing_upgrades
	upgrade_margins.visible = !upgrade_margins.visible
	upgrade_panel.visible = !upgrade_panel.visible

func show_game_screen():
	game_board.visible = true
	idle_panel.visible = false
	idle_margins.visible = false
	current_screen = Screen.GAME

func show_idle_screen():
	game_board.visible = false
	idle_margins.visible = true
	idle_panel.visible = true
	idle_panel.update_level_up_buttons()
	current_screen = Screen.IDLE

func swap_screen():
	if current_screen == Screen.GAME:
		show_idle_screen()
	else:
		show_game_screen()
	if showing_upgrades:
		showing_upgrades = false

func _on_play_again_pressed():
	reset_to_gameplay()
	board_canvas.reset_board()

func show_game_over(stats: GameStats):
	current_ui_state = "game_over"
	emit_signal("ui_state_changed", current_ui_state)
	convert_and_stash.disabled = false
	print("Idle Panel Visible:", idle_panel.visible)

	top_bar_panel.get_node("GameOverBox").visible = true
	top_bar_panel.get_node("GameOverBox/Scores/ScoreLabel").text = "Score: %d" % stats.score
	top_bar_panel.get_node("GameOverBox/Scores/MovesLabel").text = "Moves: %d" % stats.moves

	StatsTracker.record_game(stats)
	print("Games stacked: %d" % StatsTracker.games_since_last_conversion)
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

func _on_board_canvas_game_over(stats: GameStats) -> void:
	show_game_over(stats)
