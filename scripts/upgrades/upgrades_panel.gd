extends Control

@onready var upgrade_button_scene := preload("res://scenes/components/UpgradeButton.tscn")
@onready var upgrade_containers := {
	"generators": $VBoxContainer/TabContainer/Generator_Upgrades/VBoxContainer,
	"conversion": $VBoxContainer/TabContainer/Conversion_Upgrades/VBoxContainer,
	"active": $VBoxContainer/TabContainer/Active_Upgrades/VBoxContainer,
	"discipline": $VBoxContainer/TabContainer/Discipline_Upgrades/VBoxContainer,
	"reset": $VBoxContainer/TabContainer/Reset_Upgrades/VBoxContainer,
	"lore": $VBoxContainer/TabContainer/Lore_Upgrades/VBoxContainer,
}

var upgrade_data := UpgradeManager.upgrades

func _ready():
	populate_upgrades()

func populate_upgrades():
	for category in upgrade_data.keys():
		var container = upgrade_containers.get(category, null)
		if not container:
			continue
		for upgrade in upgrade_data[category]:
			var button = upgrade_button_scene.instantiate()
			button.name = upgrade["id"]
			
			var label_text = upgrade["id"].capitalize().replace("_", " ")
			if "level" in upgrade and "max_level" in upgrade:
				label_text += " (Lv %d/%d)" % [upgrade["level"], upgrade["max_level"]]
			button.text = label_text

			if upgrade.has("cost"):
				button.tooltip_text = "Cost: %d" % upgrade["cost"]
			elif upgrade.has("base_cost"):
				button.tooltip_text = "Base Cost: %d" % upgrade["base_cost"]

			button.pressed.connect(_on_upgrade_pressed.bind(category, upgrade["id"]))
			container.add_child(button)

func _on_upgrade_pressed(category: String, upgrade_id: String) -> void:
	print("Upgrade clicked: %s from %s" % [upgrade_id, category])
	# Call UpgradeManager here to apply it!
