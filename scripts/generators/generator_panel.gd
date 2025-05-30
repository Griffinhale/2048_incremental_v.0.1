extends Control

@onready var generator_list := $VBoxContainer/GeneratorContainer/ScrollContainer/GeneratorList
const GENERATOR_ENTRY_SCENE := preload("res://scenes/components/GeneratorEntry.tscn")
@onready var currency_label := $VBoxContainer/StatsContainer/CurrencyDisplay

var is_initialized := false

func _ready():
	# Wait for other managers to be ready
	call_deferred("initialize_panel")
	
	StatsTracker.new_highest_tile.connect(_on_highest_tile_changed)  # You'll need to add this signal
	
	

func initialize_panel():
	print("Initializing Generator Panel")
	
	# Connect to managers if they exist
	if GeneratorManager:
		if not GeneratorManager.is_connected("generator_updated", _on_generator_updated):
			GeneratorManager.generator_updated.connect(_on_generator_updated)
			print("Connected to GeneratorManager.generator_updated")
		
		if not GeneratorManager.is_connected("generator_unlocked", _on_generator_unlocked):
			GeneratorManager.generator_unlocked.connect(_on_generator_unlocked)
			print("Connected to GeneratorManager.generator_unlocked")
	else:
		print("GeneratorManager not found!")
	
	if CurrencyManager:
		if not CurrencyManager.is_connected("currency_changed", _on_currency_changed):
			CurrencyManager.currency_changed.connect(_on_currency_changed)
			print("Connected to CurrencyManager.currency_changed")
	else:
		print("CurrencyManager not found!")
	
	if StatsTracker:
		if not StatsTracker.is_connected("new_highest_tile", _on_highest_tile_changed):
			StatsTracker.new_highest_tile.connect(_on_highest_tile_changed)
	populate_generators()
	update_generator_display()
	update_currency_display()
	is_initialized = true


func _on_generator_unlocked(gen_id: String):
	print("Generator unlocked: ", gen_id)
	# Refresh the entire panel when a new generator is unlocked
	populate_generators()

func _on_currency_changed(currency_type: String, new_value: float):
	update_currency_display()
	update_level_up_buttons()

func update_currency_display():
	if currency_label and CurrencyManager:
		var currency = CurrencyManager.get_currency("conversion")
		currency_label.text = "Conversion Currency: %.2f" % currency
		
func populate_generators():
	if not GeneratorManager:
		print("GeneratorManager not available for populate_generators")
		return
		
	print("Populating generators")
	
	# Clear existing entries
	for child in generator_list.get_children():
		child.queue_free()
	
	# Wait for children to be freed
	await get_tree().process_frame
	
	var gens = GeneratorManager.generator_collection
	for gen in gens.generators:
		# Only show unlocked generators
		if not GeneratorManager.is_generator_unlocked(gen):
			continue
			
		var entry = GENERATOR_ENTRY_SCENE.instantiate()
		entry.name = gen["id"]
		entry.get_node("Label_ID").text = gen["label"]
		entry.get_node("Label_Level").text = "Lv " + str(gen["level"])
		entry.get_node("Label_LastYield").text = "Yield: 0.0"
		
		var button = entry.get_node("Button_LevelUp")
		button.text = "Upgrade (%.2f)" % gen.get("level_cost")
		button.pressed.connect(_on_level_up_pressed.bind(gen["id"], entry))
		
		entry.size_flags_vertical = Control.SIZE_EXPAND_FILL
		generator_list.add_child(entry)
		print("Added generator entry: ", gen["label"])
	
	update_level_up_buttons()

func update_level_up_buttons():
	if not CurrencyManager or not GeneratorManager or not generator_list:
		return
		
	var currency = CurrencyManager.get_currency("conversion")
	
	for entry in generator_list.get_children():
		if not is_instance_valid(entry):
			continue
			
		var gen_id = entry.name
		var gen = GeneratorManager.generator_collection.get_generator_by_id(gen_id)
		if gen.is_empty():
			continue
			
		var button = entry.get_node("Button_LevelUp")
		var cost = gen.get("level_cost")
		button.text = "Upgrade (%.2f)" % cost
		
		var can_afford = currency >= cost
		button.disabled = not can_afford
		
		# Visual feedback
		if can_afford:
			entry.modulate = Color(1, 1, 1, 1)
		else:
			entry.modulate = Color(0.7, 0.7, 0.7, 1)

func _on_visibility_changed() -> void:
	if not is_initialized:
		return
		
	if visible and GeneratorManager:
		GeneratorManager.refresh_generator_activation()
		populate_generators()  # Refresh in case new generators were unlocked
		update_currency_display()

# Public function to refresh the panel (can be called from UI manager)
func refresh_panel():
	if is_initialized:
		populate_generators()
		update_currency_display()
# Update your generator_panel.gd to handle locked states

func update_generator_display():
	# Clear existing entries
	for child in generator_list.get_children():
		child.queue_free()
	
	# Create entries for ALL generators, not just unlocked ones
	for gen in GeneratorManager.generator_collection.generators:
		create_generator_entry(gen)

func create_generator_entry(gen: GeneratorData):
	var entry = GENERATOR_ENTRY_SCENE.instantiate()
	var status = GeneratorManager.get_generator_unlock_status(gen)
	generator_list.add_child(entry)
	# Set up the entry with status information
	entry.setup_generator(gen, status)
	
	# Connect the level up button
	entry.level_up_button.pressed.connect(_on_level_up_pressed.bind(gen.id))
	
	

func _on_level_up_pressed(generator_id: String):
	var success = GeneratorManager.level_up_generator(generator_id)
	if success:
		# Refresh the display to show new costs/levels
		update_generator_display()

# Call this when the highest tile changes
func _on_highest_tile_changed():
	update_generator_display()



func _on_generator_updated(id: String, yield_val: float):
	# Update just the specific generator entry if needed
	update_generator_display()
