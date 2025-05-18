extends Control

@onready var generator_list := $VBoxContainer/GeneratorContainer/ScrollContainer/GeneratorList
const GENERATOR_ENTRY_SCENE := preload("res://GeneratorEntry.tscn")


@onready var currency_label := $VBoxContainer/StatsContainer/CurrencyDisplay

func _on_generator_updated(gen_id: String, yield_val: float):
	var entry = generator_list.get_node_or_null(gen_id)
	if entry:
		entry.get_node("Label_LastYield").text = "Yield: %.2f" % yield_val
	currency_label.text = "Currency: %.2f" % CurrencyManager.get_currency()

func _ready():
	populate_generators()
	GeneratorManager.generator_updated.connect(_on_generator_updated)

func populate_generators():
	var entries := generator_list.get_children()
	var gens := GeneratorManager.generators

	for i in range(min(entries.size(), gens.size())):
		var entry = entries[i]
		var gen = gens[i]

		entry.name = gen["id"]
		entry.get_node("Label_ID").text = gen["label"]
		entry.get_node("Label_Level").text = "Lv " + str(gen["level"])
		entry.get_node("Label_LastYield").text = "Yield: 0.0"

		var button = entry.get_node("Button_LevelUp")
		button.pressed.connect(_on_level_up_pressed.bind(gen["id"], entry))

func _on_level_up_pressed(gen_id: String, entry: Node):
	GeneratorManager.level_up_generator(gen_id)
	var gen = GeneratorManager.get_generator_by_id(gen_id)
	entry.get_node("Label_Level").text = "Lv " + str(gen["level"])
