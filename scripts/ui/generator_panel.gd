extends Control

@onready var generator_list := $VBoxContainer/GeneratorContainer/ScrollContainer/GeneratorList
const GENERATOR_ENTRY_SCENE := preload("res://scenes/components/GeneratorEntry.tscn")
@onready var currency_label := $VBoxContainer/StatsContainer/CurrencyDisplay

var is_initialized := false

func _ready():
	# Wait for other managers to be ready
	call_deferred("initialize_panel")
	
	StatsTracker.new_highest_tile.connect(_on_highest_tile_changed)  # You'll need to add this signal
	
	update_generator_display()

func _on_level_up_pressed(generator_id: String):
	var success = GeneratorManager.level_up_generator(generator_id)
	if success:
		print("level up")
		# Just update currency display and the specific entry
#		update_currency_display()

# Call this when the highest tile changes
func _on_highest_tile_changed():
	update_generator_display()

func _on_generator_updated(id: String, yield_val: float):
	# Update just the specific generator entry
	for child in generator_list.get_children():
		if is_instance_valid(child) and child.name == id:
			var gen = GeneratorManager.generator_collection.get_generator_by_id(id)
			if gen:
				update_generator_entry_data(child, gen)
			break

func _on_generator_unlocked(gens: Array):
	print("Generator unlocked: ", gens)
	# Refresh the entire panel when a new generator is unlocked
	#populate_generators()

func _on_currency_changed(currency_type: String, new_value: float):
	if currency_label and currency_type == "conversion":
		currency_label.text = "Conversion Currency: %.2f" % new_value
	#update_level_up_buttons()

func _on_visibility_changed() -> void:
	if not is_initialized:
		return
		
	if visible and GeneratorManager:
		print(GeneratorManager.generator_collection)
		GeneratorManager.refresh_generator_activation()
		populate_generators()  # Refresh in case new generators were unlocked
#		update_currency_display()
		print(GeneratorManager.generator_collection)


func update_generator_entry_data(entry: Control, gen: GeneratorData):
	if not is_instance_valid(entry):
		return
		
	entry.get_node("Label_ID").text = gen["label"]
	entry.get_node("Label_Level").text = "Lv " + str(gen["level"])
	
	# Get the last yield from GeneratorManager debug data
	var last_yield = 0.0
	if GeneratorManager.debug_data.last_yields.has(gen["id"]):
		last_yield = GeneratorManager.debug_data.last_yields[gen["id"]]
	
	entry.get_node("Label_LastYield").text = "Yield: %.2f" % last_yield
	
	var button = entry.get_node("Button_LevelUp")
	button.text = "Upgrade (%.2f)" % gen.get("level_cost")
	
	# Update affordability
	if CurrencyManager:
		var currency = CurrencyManager.get_currency("conversion")
		var cost = gen.get("level_cost")
		var can_afford = currency >= cost
		button.disabled = not can_afford
		
		# Visual feedback
		if can_afford:
			entry.modulate = Color(1, 1, 1, 1)
		else:
			entry.modulate = Color(0.7, 0.7, 0.7, 1)

func populate_generators():
	if not GeneratorManager:
		print("GeneratorManager not available for populate_generators")
		return
		
	print("Populating generators")
	
	# Clear existing entries completely to avoid duplicates
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
		
		# Set up the entry data
		update_generator_entry_data(entry, gen)
		
		# Connect the level up button
		var button = entry.get_node("Button_LevelUp")
		button.pressed.connect(_on_level_up_pressed.bind(gen["id"]))
		
		entry.size_flags_vertical = Control.SIZE_EXPAND_FILL
		generator_list.add_child(entry)
		print("Added generator entry: ", gen["label"])

func update_level_up_buttons():
	if not CurrencyManager or not GeneratorManager or not generator_list:
		return
		
	var currency = CurrencyManager.get_currency("conversion")
	
	for entry in generator_list.get_children():
		if not is_instance_valid(entry):
			continue
			
		var gen_id = entry.name
		var gen = GeneratorManager.generator_collection.get_generator_by_id(gen_id)
		if !gen:
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

func initialize_panel():
	print("Initializing Generator Panel")
	
	# Connect to managers if they exist
	if GeneratorManager:
		if not GeneratorManager.is_connected("generator_updated", _on_generator_updated):
			GeneratorManager.generator_updated.connect(_on_generator_updated)
			print("Connected to GeneratorManager.generator_updated")
		
		if not GeneratorManager.is_connected("generator_unlocked", _on_generator_unlocked):
			GeneratorManager.generators_unlocked.connect(_on_generator_unlocked)
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
	
#$	update_currency_display()
	is_initialized = true

func refresh_panel():
	if is_initialized:
		populate_generators()
#		update_currency_display()

func update_generator_display():
	# Just refresh the existing entries without rebuilding
	for child in generator_list.get_children():
		if is_instance_valid(child):
			var gen_id = child.name
			var gen = GeneratorManager.generator_collection.get_generator_by_id(gen_id)
			if gen:
				update_generator_entry_data(child, gen)

func update_generator_entry(entry: Control, gen: GeneratorData):
	if not is_instance_valid(entry):
		return
		
	entry.get_node("Label_ID").text = gen["label"]
	entry.get_node("Label_Level").text = "Lv " + str(gen["level"])
	
	# Get the last yield from GeneratorManager debug data
	var last_yield = 0.0
	if GeneratorManager.debug_data.last_yields.has(gen["id"]):
		last_yield = GeneratorManager.debug_data.last_yields[gen["id"]]
	
	entry.get_node("Label_LastYield").text = "Yield: %.2f" % last_yield
	
	var button = entry.get_node("Button_LevelUp")
	button.text = "Upgrade (%.2f)" % gen.get("level_cost")
	
	# Update affordability
	if CurrencyManager:
		var currency = CurrencyManager.get_currency("conversion")
		var cost = gen.get("level_cost")
		var can_afford = currency >= cost
		button.disabled = not can_afford
		
		# Visual feedback
		if can_afford:
			entry.modulate = Color(1, 1, 1, 1)
		else:
			entry.modulate = Color(0.7, 0.7, 0.7, 1)

func create_new_generator_entry(gen: GeneratorData):
	var entry = GENERATOR_ENTRY_SCENE.instantiate()
	entry.name = gen["id"]
	
	# Set up initial values
	update_generator_entry(entry, gen)
	
	# Connect button
	var button = entry.get_node("Button_LevelUp")
	button.pressed.connect(_on_level_up_pressed.bind(gen["id"], entry))
	
	entry.size_flags_vertical = Control.SIZE_EXPAND_FILL
	generator_list.add_child(entry)
	print("Created new generator entry: ", gen["label"])
