extends Control

@onready var generator_list := $VBoxContainer/GeneratorContainer/ScrollContainer/GeneratorList
const GENERATOR_ENTRY_SCENE := preload("res://scenes/components/GeneratorEntry.tscn")


@onready var currency_label := $VBoxContainer/StatsContainer/CurrencyDisplay

func _on_generator_updated(gen_id: String, yield_val: float):
	var entry = generator_list.get_node_or_null(gen_id)
	if entry:
		entry.get_node("Label_LastYield").text = "Yield: %.2f" % yield_val

func _ready():
	populate_generators()
	GeneratorManager.generator_updated.connect(_on_generator_updated)
	CurrencyManager.currency_changed.connect(_on_currency_changed)
	_on_currency_changed(CurrencyManager.get_currency())
	
func _on_currency_changed(new_value: float):
	currency_label.text = "Currency: %.2f" % new_value
	update_level_up_buttons()
	
func populate_generators():
	for child in generator_list.get_children():
		child.queue_free()

	var gens := GeneratorManager.generators

	for gen in gens:
		var entry = GENERATOR_ENTRY_SCENE.instantiate()
		entry.name = gen["id"]
		entry.get_node("Label_ID").text = gen["label"]
		entry.get_node("Label_Level").text = "Lv " + str(gen["level"])
		entry.get_node("Label_LastYield").text = "Yield: 0.0"

		var button = entry.get_node("Button_LevelUp")
		button.text = "Upgrade (%.2f)" % gen.get("level_cost", 1.0)
		button.pressed.connect(_on_level_up_pressed.bind(gen["id"], entry))
		entry.size_flags_vertical = SIZE_EXPAND_FILL
		generator_list.add_child(entry)



func _on_level_up_pressed(gen_id: String, entry: Node):
	GeneratorManager.level_up_generator(gen_id)
	var gen = GeneratorManager.get_generator_by_id(gen_id)
	entry.get_node("Label_Level").text = "Lv " + str(gen["level"])
	entry.get_node("Button_LevelUp").text = "Upgrade (%.2f)" % gen.get("level_cost", 1.0)
	update_level_up_buttons()

func update_level_up_buttons():
	var currency = CurrencyManager.get_currency()
	if !generator_list:
		return
		
	for entry in generator_list.get_children():
		var gen_id = entry.name
		var gen = GeneratorManager.get_generator_by_id(gen_id)
		if not gen:
			continue

		var button = entry.get_node("Button_LevelUp")
		button.text = "Upgrade (%.2f)" % gen.get("level_cost", 1.0)
		
		if currency > gen.get("level_cost"):
			entry.modulate = Color(1, 1, 1, 1)
			button.disabled = currency < gen.get("level_cost", 1.0)
		else:
			entry.modulate = Color(0.5, 0.5, 0.5, 1)
			button.disabled = true
		



func _on_visibility_changed() -> void:
	GeneratorManager.refresh_generator_activation()
	update_level_up_buttons()
