extends Control

@onready var generator_list := $VBoxContainer/GeneratorContainer/ScrollContainer/GeneratorList
const GENERATOR_ENTRY_SCENE := preload("res://scenes/components/GeneratorEntry.tscn")
@onready var currency_label := $VBoxContainer/StatsContainer/CurrencyDisplay

var is_initialized := false

func _ready():
	# Wait for other managers to be ready
	call_deferred("initialize_panel")

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
	
	populate_generators()
	update_currency_display()
	is_initialized = true

func _on_generator_updated(gen_id: String, yield_val: float):
	var entry = generator_list.get_node_or_null(gen_id)
	if entry:
		entry.get_node("Label_LastYield").text = "Yield: %.2f" % yield_val
		print("Updated generator %s yield display: %.2f" % [gen_id, yield_val])

func _on_generator_unlocked(gen_id: String):
	print("Generator unlocked: ", gen_id)
	# Refresh the entire panel when a new generator is unlocked
	populate_generators()

func _on_currency_changed(new_value: float):
	update_currency_display()
	update_level_up_buttons()

func update_currency_display():
	if currency_label and CurrencyManager:
		var currency = CurrencyManager.get_currency("conversion")
		currency_label.text = "Conversion Currency: %.2f" % currency
		print("Updated currency display: %.2f" % currency)

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

func _on_level_up_pressed(gen_id: String, entry: Node):
	print("Level up pressed for: ", gen_id)
	
	if GeneratorManager.level_up_generator(gen_id):
		var gen = GeneratorManager.get_generator_by_id(gen_id)
		entry.get_node("Label_Level").text = "Lv " + str(gen["level"])
		entry.get_node("Button_LevelUp").text = "Upgrade (%.2f)" % gen.get("level_cost")
		update_level_up_buttons()
		print("Successfully leveled up: ", gen_id)
	else:
		print("Failed to level up: ", gen_id)

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
