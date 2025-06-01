# Update your GeneratorEntry.gd (or create it if it doesn't exist)

extends Control

@onready var name_label: Label = $GeneratorEntry/Label_ID
@onready var level_label: Label = $Label_Level
@onready var yield_label: Label = $Label_LastYield
@onready var level_up_button: Button = $Button_LevelUp
@onready var target_tiles_label: Label = $VBoxContainer/TargetTilesLabel
@onready var unlock_status_label: Label = $VBoxContainer/UnlockStatusLabel

var generator_data: GeneratorData
var unlock_status: Dictionary

func _ready() -> void:
	pass
	#setup gen entry label creation via code, to ensure they're created before any setups are done?

func setup_generator(gen: GeneratorData, status: Dictionary):
	generator_data = gen
	unlock_status = status
	
	# Basic info
	if name_label:
		
		name_label.text = gen.label
		level_label.text = "Level: %d" % gen.level
		level_up_button.text = "Cost: %.1f" % gen.level_cost
	
	# Target tiles info
	var tile_values = []
	for tile_power in gen.tile_targets:
		tile_values.append(str(int(pow(2, tile_power))))
	#target_tiles_label.text = "Targets: %s" % ", ".join(tile_values)
	
	# Yield info (only show if active and leveled)
	if gen.level > 0 and status.unlocked:
		var current_yield = GeneratorManager.calculate_yield(gen)
		yield_label.text = "Yield: %.2f/%.1fs" % [current_yield, gen.interval_seconds]
		yield_label.visible = true
	else:
		yield_label.visible = false
	
	# Update unlock status and button state
	update_unlock_status()

func update_unlock_status():
	if unlock_status.unlocked:
		# Generator is unlocked
#		unlock_status_label.visible = false
		level_up_button.disabled = not unlock_status.can_afford
		level_up_button.text = "Level Up" if unlock_status.can_afford else "Not Enough Currency"
		
		# Normal colors
		modulate = Color.WHITE
		
	else:
		# Generator is locked
#		unlock_status_label.visible = true
		
		# Show what tiles are needed
		var blocking_values = []
		for tile_power in unlock_status.blocking_tiles:
			blocking_values.append(str(int(pow(2, tile_power))))
		
#		unlock_status_label.text = "Locked - Need: %s" % ", ".join(blocking_values)
		level_up_button.disabled = true
		level_up_button.text = "Locked"
		
		# Grey out the entire entry
		modulate = Color(0.6, 0.6, 0.6, 1.0)

# Optional: Add tooltip for more detailed info
func _on_mouse_entered():
	if not unlock_status.unlocked:
		var tooltip_text = "Reach tile %s to unlock this generator" % unlock_status.blocking_tiles
		# You could show a tooltip here
