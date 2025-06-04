extends Control

## Tree management UI with drag-and-drop progression zones
## Implements tiered upgrade system with visual progression mechanics

signal tree_selected(tree_name: String)
signal tree_deselected()

## UI Container References
@onready var keystone_zone: HBoxContainer = $VBox/KeystoneZone
@onready var advanced_zone: HBoxContainer = $VBox/AdvancedZone  
@onready var starter_zone: HBoxContainer = $VBox/StarterZone
@onready var tree_detail_panel: Control = $TreeDetailPanel
@onready var tree_detail_content: Control = $TreeDetailPanel/Content

## Tree UI state
var tree_widgets: Dictionary = {}  # tree_name -> TreeWidget
var selected_tree: String = ""
var upgrade_manager: UpgradeManager

## Zone configuration
var zone_configs = {
	"keystone": {
		"max_trees": 2,
		"requires_tier": 3,
		"allows_keystones": true,
		"container": null  # Set in _ready
	},
	"advanced": {
		"max_trees": 2, 
		"requires_tier": 2,
		"allows_keystones": false,
		"container": null
	},
	"starter": {
		"max_trees": 6,
		"requires_tier": 1,
		"allows_keystones": false,
		"container": null
	}
}

func _ready():
	# Set up zone container references
	zone_configs["keystone"]["container"] = keystone_zone
	zone_configs["advanced"]["container"] = advanced_zone
	zone_configs["starter"]["container"] = starter_zone
	
	# Get upgrade manager reference
	upgrade_manager = get_node("/root/UpgradeManager")
	if not upgrade_manager:
		push_error("UpgradesPanel: UpgradeManager not found")
		return
	
	# Connect to upgrade manager signals
	upgrade_manager.upgrade_purchased.connect(_on_upgrade_purchased)
	upgrade_manager.tier_unlocked.connect(_on_tier_unlocked)
	upgrade_manager.tree_reset.connect(_on_tree_reset)
	
	# Initialize UI
	_setup_ui()
	_create_tree_widgets()
	_organize_trees_by_tier()
	
	# Close tree detail panel initially
	tree_detail_panel.visible = false
	add_to_group("upgrades_panel")

func _setup_ui():
	# Set up zone styling and properties
	for zone_name in zone_configs.keys():
		var zone = zone_configs[zone_name]
		var container = zone["container"]
		
		if container:
		# Add drop zone styling
			container.add_theme_stylebox_override("panel", _create_zone_style(zone_name))
		
		# Set up size constraints
			match zone_name:
				"keystone":
					container.custom_minimum_size = Vector2(400, 120)
				"advanced":
					container.custom_minimum_size = Vector2(400, 120)
				"starter":
					container.custom_minimum_size = Vector2(600, 80)

func _create_zone_style(zone_name: String) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	
	match zone_name:
		"keystone":
			style.bg_color = Color(0.9, 0.8, 0.6, 0.3)  # Gold tint
			style.border_color = Color(0.8, 0.7, 0.4)
		"advanced": 
			style.bg_color = Color(0.8, 0.9, 0.8, 0.3)  # Green tint
			style.border_color = Color(0.6, 0.8, 0.6)
		"starter":
			style.bg_color = Color(0.8, 0.8, 0.9, 0.3)  # Blue tint
			style.border_color = Color(0.6, 0.6, 0.8)
	
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	
	return style

func _create_tree_widgets():
	# Create widgets for available trees
	var available_trees = upgrade_manager.get_available_trees()
	
	for tree_name in available_trees:
		var widget = _create_tree_widget(tree_name)
		tree_widgets[tree_name] = widget

func _create_tree_widget(tree_name: String) -> Control:
	var widget = preload("res://scenes/components/TreeWidget.tscn").instantiate()
	
	# Configure the widget
	widget.setup_tree(tree_name, upgrade_manager)
	
	# Connect widget signals
	widget.tree_clicked.connect(_on_tree_widget_clicked.bind(tree_name))
	widget.tree_drag_started.connect(_on_tree_drag_started.bind(tree_name))
	widget.tree_dropped.connect(_on_tree_dropped)
	
	return widget

func _organize_trees_by_tier():
	# Clear all zones first
	for zone_name in zone_configs.keys():
		var container = zone_configs[zone_name]["container"]
		if container:		
			for child in container.get_children():
				if child in tree_widgets.values():
					container.remove_child(child)
		
	# Place trees in appropriate zones based on their tier
	for tree_name in tree_widgets.keys():
		var tree = upgrade_manager.get_tree_instance(tree_name)
		var current_tier = tree.tree_data.current_tier
		
		var target_zone = _determine_tree_zone(tree_name, current_tier)
		var container = zone_configs[target_zone]["container"]
		
		container.add_child(tree_widgets[tree_name])

func _determine_tree_zone(tree_name: String, current_tier: int) -> String:
	# Determine which zone a tree should be in based on its tier
	if current_tier >= 3:
		# Check if keystone zone has space
		if zone_configs["keystone"]["container"].get_child_count() < zone_configs["keystone"]["max_trees"]:
			return "keystone"
		# Fall back to advanced if keystone is full
		elif zone_configs["advanced"]["container"].get_child_count() < zone_configs["advanced"]["max_trees"]:
			return "advanced"
	elif current_tier >= 2:
		# Advanced tier trees
		if zone_configs["advanced"]["container"].get_child_count() < zone_configs["advanced"]["max_trees"]:
			return "advanced"
	
	# Default to starter zone
	return "starter"

## Tree selection and detail view
func _on_tree_widget_clicked(tree_name: String):
	if selected_tree == tree_name:
		# Deselect if clicking the same tree
		_deselect_tree()
	else:
		_select_tree(tree_name)

func _select_tree(tree_name: String):
	# Deselect previous tree
	if selected_tree != "":
		_deselect_tree()
	
	selected_tree = tree_name
	
	# Update widget visual state
	if tree_widgets.has(tree_name):
		tree_widgets[tree_name].set_selected(true)
	
	# Show tree detail panel
	_show_tree_details(tree_name)
	
	tree_selected.emit(tree_name)

func _deselect_tree():
	if selected_tree != "":
		# Update widget visual state
		if tree_widgets.has(selected_tree):
			tree_widgets[selected_tree].set_selected(false)
		
		selected_tree = ""
		
		# Hide tree detail panel
		tree_detail_panel.visible = false
		
		tree_deselected.emit()

func _show_tree_details(tree_name: String):
	# Clear existing content
	for child in tree_detail_content.get_children():
		child.queue_free()
	
	# Create tree detail view
	var detail_view = _create_tree_detail_view(tree_name)
	tree_detail_content.add_child(detail_view)
	
	# Show and animate the panel
	tree_detail_panel.visible = true
	_animate_panel_in()

func _create_tree_detail_view(tree_name: String) -> Control:
	var detail_container = VBoxContainer.new()
	
	# Tree header
	var header = _create_tree_header(tree_name)
	detail_container.add_child(header)
	
	# XP and tier info
	var progress_info = _create_progress_info(tree_name)
	detail_container.add_child(progress_info)
	
	# Upgrade list
	var upgrade_list = _create_upgrade_list(tree_name)
	detail_container.add_child(upgrade_list)
	
	return detail_container

func _create_tree_header(tree_name: String) -> Control:
	var header = HBoxContainer.new()
	
	# Tree name
	var name_label = Label.new()
	name_label.text = tree_name + " Tree"
	name_label.add_theme_font_size_override("font_size", 24)
	header.add_child(name_label)
	
	# Close button
	var close_button = Button.new()
	close_button.text = "×"
	close_button.custom_minimum_size = Vector2(30, 30)
	close_button.pressed.connect(_deselect_tree)
	header.add_child(close_button)
	
	return header

func _create_progress_info(tree_name: String) -> Control:
	var progress_container = VBoxContainer.new()
	
	var tree = upgrade_manager.get_tree_instance(tree_name)
	var xp_type = tree._get_xp_currency_type()
	var current_xp = upgrade_manager.currency_manager.get_currency(xp_type)
	
	# XP display
	var xp_label = Label.new()
	xp_label.text = "XP: " + str(int(current_xp))
	progress_container.add_child(xp_label)
	
	# Tier progress
	var tier_label = Label.new()
	tier_label.text = "Current Tier: " + str(tree.tree_data.current_tier)
	progress_container.add_child(tier_label)
	
	# Next tier progress (if applicable)
	var next_tier = tree.tree_data.current_tier + 1
	if next_tier <= 3:
		var progress = tree.get_tier_progress(next_tier)
		var progress_bar = ProgressBar.new()
		progress_bar.value = progress * 100
		progress_bar.custom_minimum_size = Vector2(200, 20)
		
		var progress_label = Label.new()
		progress_label.text = "Tier " + str(next_tier) + " Progress: " + str(int(progress * 100)) + "%"
		
		progress_container.add_child(progress_label)
		progress_container.add_child(progress_bar)
	
	return progress_container

func _create_upgrade_list(tree_name: String) -> Control:
	var scroll_container = ScrollContainer.new()
	scroll_container.custom_minimum_size = Vector2(400, 300)
	
	var upgrade_container = VBoxContainer.new()
	scroll_container.add_child(upgrade_container)
	
	var tree = upgrade_manager.get_tree_instance(tree_name)
	
	# Group upgrades by tier
	for tier in range(1, 4):
		var tier_label = Label.new()
		tier_label.text = "Tier " + str(tier) + " Upgrades"
		tier_label.add_theme_font_size_override("font_size", 18)
		upgrade_container.add_child(tier_label)
		
		# Get upgrades for this tier
		var tier_upgrades = _get_tier_upgrades(tree, tier)
		
		if tier_upgrades.is_empty():
			var no_upgrades_label = Label.new()
			no_upgrades_label.text = "  No upgrades available"
			no_upgrades_label.modulate = Color.GRAY
			upgrade_container.add_child(no_upgrades_label)
		else:
			for upgrade_id in tier_upgrades:
				var upgrade_button = _create_upgrade_button(tree_name, upgrade_id)
				upgrade_container.add_child(upgrade_button)
		
		# Add separator
		var separator = HSeparator.new()
		upgrade_container.add_child(separator)
	
	return scroll_container

func _get_tier_upgrades(tree: Tree, tier: int) -> Array:
	var tier_upgrades = []
	
	for upgrade_id in tree.upgrade_definitions.keys():
		var upgrade_def = tree.upgrade_definitions[upgrade_id]
		if upgrade_def.get("tier", 1) == tier:
			tier_upgrades.append(upgrade_id)
	
	return tier_upgrades

func _create_upgrade_button(tree_name: String, upgrade_id: String) -> Control:
	var upgrade_info = upgrade_manager.get_upgrade_info(tree_name, upgrade_id)
	
	var button_container = HBoxContainer.new()
	
	# Main upgrade button
	var upgrade_button = Button.new()
	upgrade_button.custom_minimum_size = Vector2(300, 60)
	upgrade_button.disabled = not upgrade_info.get("available", false) or not upgrade_info.get("can_afford", false)
	
	# Button text with name, cost, and status
	var button_text = upgrade_info.get("name", upgrade_id)
	if upgrade_info.get("purchased", false):
		button_text += " ✓"
		upgrade_button.disabled = true
	else:
		button_text += " (" + str(upgrade_info.get("cost", 0)) + " XP)"
	
	upgrade_button.text = button_text
	upgrade_button.pressed.connect(_on_upgrade_button_pressed.bind(tree_name, upgrade_id))
	
	button_container.add_child(upgrade_button)
	
	# Description label
	var description = Label.new()
	description.text = upgrade_info.get("description", "")
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size = Vector2(200, 0)
	button_container.add_child(description)
	
	return button_container

## Drag and drop handling
func _on_tree_drag_started(tree_name: String):
	# Visual feedback for drag operation
	_highlight_valid_drop_zones(tree_name)

func _on_tree_dropped(tree_name: String, drop_zone: String):
	# Handle tree movement between zones
	if _can_tree_move_to_zone(tree_name, drop_zone):
		_move_tree_to_zone(tree_name, drop_zone)
	
	_clear_drop_zone_highlights()

func _highlight_valid_drop_zones(tree_name: String):
	# Add visual feedback for valid drop zones
	var tree = upgrade_manager.get_tree_instance(tree_name)
	var current_tier = tree.tree_data.current_tier
	
	for zone_name in zone_configs.keys():
		var zone_config = zone_configs[zone_name]
		var container = zone_config["container"]
		
		if _can_tree_move_to_zone(tree_name, zone_name):
			container.modulate = Color.WHITE
		else:
			container.modulate = Color(0.5, 0.5, 0.5, 0.7)

func _clear_drop_zone_highlights():
	for zone_name in zone_configs.keys():
		var container = zone_configs[zone_name]["container"]
		container.modulate = Color.WHITE

func _can_tree_move_to_zone(tree_name: String, zone_name: String) -> bool:
	var tree = upgrade_manager.get_tree_instance(tree_name)
	var current_tier = tree.tree_data.current_tier
	var zone_config = zone_configs[zone_name]
	
	# Check tier requirement
	if current_tier < zone_config["requires_tier"]:
		return false
	
	# Check zone capacity
	if zone_config["container"].get_child_count() >= zone_config["max_trees"]:
		# Allow if tree is already in this zone
		return tree_widgets[tree_name].get_parent() == zone_config["container"]
	
	return true

func _move_tree_to_zone(tree_name: String, zone_name: String):
	var widget = tree_widgets[tree_name]
	var new_container = zone_configs[zone_name]["container"]
	
	# Remove from current parent
	if widget.get_parent():
		widget.get_parent().remove_child(widget)
	
	# Add to new container
	new_container.add_child(widget)

## Signal handlers
func _on_upgrade_purchased(tree_name: String, upgrade_id: String):
	# Refresh the selected tree's detail view if it's the purchased tree
	if selected_tree == tree_name:
		_show_tree_details(tree_name)
	
	# Update tree widget visual state
	if tree_widgets.has(tree_name):
		tree_widgets[tree_name].refresh_state()

func _on_tier_unlocked(tree_name: String, tier: int):
	# Check if tree should move to a different zone
	_organize_trees_by_tier()
	
	# Refresh detail view if this tree is selected
	if selected_tree == tree_name:
		_show_tree_details(tree_name)

func _on_tree_reset(tree_name: String):
	# Move tree back to starter zone and refresh
	_organize_trees_by_tier()
	
	if selected_tree == tree_name:
		_show_tree_details(tree_name)

func _on_upgrade_button_pressed(tree_name: String, upgrade_id: String):
	upgrade_manager.purchase_upgrade(tree_name, upgrade_id)

## Animation methods
func _animate_panel_in():
	var tween = create_tween()
	tree_detail_panel.modulate.a = 0.0
	tree_detail_panel.scale = Vector2(0.8, 0.8)
	
	tween.parallel().tween_property(tree_detail_panel, "modulate:a", 1.0, 0.3)
	tween.parallel().tween_property(tree_detail_panel, "scale", Vector2(1.0, 1.0), 0.3)
	tween.set_ease(Tween.EASE_OUT)

## Input handling
func _input(event):
	if event is InputEventMouseButton and event.pressed:
		# Check if clicking outside the detail panel to close it
		if tree_detail_panel.visible and selected_tree != "":
			var panel_rect = tree_detail_panel.get_global_rect()
			if not panel_rect.has_point(event.global_position):
				_deselect_tree()

## Public interface methods
func refresh_panel():
	_organize_trees_by_tier()
	
	# Refresh selected tree details if any
	if selected_tree != "":
		_show_tree_details(selected_tree)

func select_tree_programmatically(tree_name: String):
	if tree_widgets.has(tree_name):
		_select_tree(tree_name)
