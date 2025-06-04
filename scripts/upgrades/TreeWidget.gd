extends Control
class_name TreeWidget

## Individual upgrade tree widget for the tree management UI
## Displays tree status, handles clicks, and supports drag-and-drop

signal tree_clicked(tree_name: String)
signal tree_drag_started(tree_name: String)
signal tree_dropped(tree_name: String, zone_name: String)

## Tree data
var tree_name: String = ""
var upgrade_manager: UpgradeManager
var tree_instance: Tree

## UI state
var is_selected: bool = false
var is_dragging: bool = false
var drag_offset: Vector2

## Visual configuration
var base_size: Vector2 = Vector2(100, 80)
var selected_size: Vector2 = Vector2(120, 100)

## UI Elements
var background_panel: Panel
var tree_icon: Control
var tree_label: Label
var tier_indicator: Control
var progress_bar: ProgressBar
var xp_label: Label

func _ready():
	_setup_ui()
	_setup_input_handling()

func _setup_ui():
	# Set initial size
	custom_minimum_size = base_size
	size = base_size
	
	# Create background panel
	background_panel = Panel.new()
	background_panel.size = size
	background_panel.anchors_preset = Control.PRESET_FULL_RECT
	add_child(background_panel)
	
	# Main container for content
	var main_container = VBoxContainer.new()
	main_container.anchors_preset = Control.PRESET_FULL_RECT
	main_container.add_theme_constant_override("separation", 2)
	add_child(main_container)
	
	# Tree icon/visual (the blue rectangle from your image)
	tree_icon = Control.new()
	tree_icon.custom_minimum_size = Vector2(60, 40)
	tree_icon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_container.add_child(tree_icon)
	
	# Tree name label
	tree_label = Label.new()
	tree_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tree_label.add_theme_font_size_override("font_size", 10)
	tree_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	main_container.add_child(tree_label)
	
	# Tier indicator (small visual indicator)
	tier_indicator = Control.new()
	tier_indicator.custom_minimum_size = Vector2(50, 8)
	tier_indicator.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_container.add_child(tier_indicator)
	
	# XP progress (tiny progress bar)
	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(60, 6)
	progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_bar.show_percentage = false
	main_container.add_child(progress_bar)

func _setup_input_handling():
	# Enable mouse input
	mouse_filter = Control.MOUSE_FILTER_PASS

func setup_tree(p_tree_name: String, p_upgrade_manager: UpgradeManager):
	tree_name = p_tree_name
	upgrade_manager = p_upgrade_manager
	tree_instance = upgrade_manager.get_tree_instance(tree_name)
	
	if not tree_instance:
		push_error("TreeWidget: Could not find tree instance for " + tree_name)
		return
	
	# Set up visual appearance
	_update_tree_display()
	_update_tree_styling()

func _update_tree_display():
	if not tree_instance:
		return
	
	# Update tree name
	tree_label.text = tree_name
	
	# Update tier indicator
	_update_tier_indicator()
	
	# Update progress bar
	_update_progress_display()
	
	# Update icon styling
	_update_icon_styling()

func _update_tier_indicator():
	# Visual indicator showing current tier (small dots or bars)
	tier_indicator.queue_redraw()

func _update_progress_display():
	var next_tier = tree_instance.tree_data.current_tier + 1
	if next_tier <= 3:
		var progress = tree_instance.get_tier_progress(next_tier)
		progress_bar.value = progress * 100
		progress_bar.visible = true
	else:
		progress_bar.visible = false

func _update_icon_styling():
	tree_icon.queue_redraw()

func _update_tree_styling():
	var style = _create_tree_style()
	background_panel.add_theme_stylebox_override("panel", style)

func _create_tree_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	
	# Base colors based on tree type
	var base_color = _get_tree_color()
	var border_color = base_color.darkened(0.3)
	
	# Adjust for selection state
	if is_selected:
		base_color = base_color.lightened(0.2)
		border_color = Color.WHITE
	
	style.bg_color = base_color
	style.border_color = border_color
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	
	# Add shadow effect for selected state
	if is_selected:
		style.shadow_color = Color(0, 0, 0, 0.3)
		style.shadow_size = 4
		style.shadow_offset = Vector2(2, 2)
	
	return style

func _get_tree_color() -> Color:
	# Color coding for different tree types
	match tree_name:
		"Active":
			return Color(0.8, 0.9, 1.0)  # Light blue
		"Conversion":
			return Color(0.9, 1.0, 0.8)  # Light green
		"Generators":
			return Color(1.0, 0.9, 0.8)  # Light orange
		"Discipline":
			return Color(1.0, 0.8, 0.8)  # Light red
		"Reset":
			return Color(0.9, 0.8, 1.0)  # Light purple
		"Lore":
			return Color(0.8, 1.0, 1.0)  # Light cyan
		_:
			return Color(0.9, 0.9, 0.9)  # Light gray

func set_selected(selected: bool):
	is_selected = selected
	_update_tree_styling()
	
	# Animate size change
	var tween = create_tween()
	var target_size = selected_size if selected else base_size
	tween.tween_property(self, "custom_minimum_size", target_size, 0.2)
	tween.parallel().tween_property(self, "size", target_size, 0.2)

func refresh_state():
	_update_tree_display()

## Custom drawing for tree icon and tier indicator
func _draw():
	if not tree_instance:
		return

func _on_tree_icon_draw():
	# Draw the main tree visualization (the blue rectangle with lines)
	var icon_rect = tree_icon.get_rect()
	var color = _get_tree_color().darkened(0.2)
	
	# Draw main rectangle
	tree_icon.draw_rect(icon_rect, color)
	
	# Draw tier lines (similar to your image)
	var current_tier = tree_instance.tree_data.current_tier
	var line_width = 3
	var line_color = Color.WHITE
	
	# Draw vertical lines based on tier
	for i in range(min(current_tier, 3)):
		var x_pos = icon_rect.position.x + (i + 1) * (icon_rect.size.x / 4)
		var start_pos = Vector2(x_pos, icon_rect.position.y + 5)
		var end_pos = Vector2(x_pos, icon_rect.position.y + icon_rect.size.y - 5)
		tree_icon.draw_line(start_pos, end_pos, line_color, line_width)

func _on_tier_indicator_draw():
	# Draw tier progress indicator
	var indicator_rect = tier_indicator.get_rect()
	var current_tier = tree_instance.tree_data.current_tier
	
	# Draw dots for each tier
	var dot_size = 4
	var dot_spacing = 8
	var start_x = (indicator_rect.size.x - (3 * dot_spacing)) / 2
	
	for i in range(3):
		var dot_pos = Vector2(start_x + i * dot_spacing, indicator_rect.size.y / 2)
		var dot_color = Color.GRAY
		
		if i < current_tier:
			dot_color = _get_tree_color().darkened(0.3)
		
		tier_indicator.draw_circle(dot_pos, dot_size / 2, dot_color)

## Input handling
func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_start_interaction(event.position)
			else:
				_end_interaction(event.position)
	
	elif event is InputEventMouseMotion and is_dragging:
		_handle_drag(event.position)

func _start_interaction(position: Vector2):
	# Start potential drag or click
	drag_offset = position
	
	# Short delay to distinguish between click and drag
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 0.1
	timer.one_shot = true
	timer.timeout.connect(_check_for_drag)
	timer.start()

func _check_for_drag():
	# If mouse hasn't moved much, treat as click
	var current_mouse_pos = get_local_mouse_position()
	if current_mouse_pos.distance_to(drag_offset) < 10:
		_handle_click()
	else:
		_start_drag()

func _handle_click():
	tree_clicked.emit(tree_name)

func _start_drag():
	is_dragging = true
	# Visual feedback for drag start
	modulate = Color(1.0, 1.0, 1.0, 0.8)
	tree_drag_started.emit(tree_name)

func _handle_drag(position: Vector2):
	if not is_dragging:
		return
	
	# Move widget with mouse
	global_position = get_global_mouse_position() - drag_offset

func _end_interaction(position: Vector2):
	if is_dragging:
		_end_drag()
	
	# Clean up any timers
	for child in get_children():
		if child is Timer:
			child.queue_free()

func _end_drag():
	is_dragging = false
	modulate = Color.WHITE
	
	# Determine drop zone
	var drop_zone = _detect_drop_zone()
	if drop_zone != "":
		tree_dropped.emit(tree_name, drop_zone)
	
	# Snap back to original position if no valid drop
	_snap_back_to_container()

func _detect_drop_zone() -> String:
	# Get the upgrades panel to check drop zones
	var upgrades_panel = get_tree().get_first_node_in_group("upgrades_panel")
	if not upgrades_panel:
		return ""
	
	var mouse_pos = get_global_mouse_position()
	
	# Check each zone
	for zone_name in ["keystone", "advanced", "starter"]:
		var zone_container = upgrades_panel.zone_configs[zone_name]["container"]
		var zone_rect = zone_container.get_global_rect()
		
		if zone_rect.has_point(mouse_pos):
			return zone_name
	
	return ""

func _snap_back_to_container():
	# Return to original position in container
	var tween = create_tween()
	tween.tween_property(self, "position", Vector2.ZERO, 0.3)
	tween.set_ease(Tween.EASE_OUT)

## Public interface methods
func get_tree_info() -> Dictionary:
	if not tree_instance:
		return {}
	
	return {
		"name": tree_name,
		"tier": tree_instance.tree_data.current_tier,
		"purchased_upgrades": tree_instance.get_purchased_upgrades().size(),
		"available_upgrades": tree_instance.get_available_upgrades().size(),
		"keystone_unlocked": tree_instance.tree_data.keystone_unlocked
	}

func can_move_to_tier(required_tier: int) -> bool:
	if not tree_instance:
		return false
	
	return tree_instance.tree_data.current_tier >= required_tier

## Animation helpers
func highlight_as_valid_drop():
	modulate = Color(1.2, 1.2, 1.2, 1.0)

func highlight_as_invalid_drop():
	modulate = Color(0.8, 0.8, 0.8, 0.7)

func clear_highlight():
	modulate = Color.WHITE

## Connect custom draw functions
func _connect_draw_signals():
	tree_icon.draw.connect(_on_tree_icon_draw)
	tier_indicator.draw.connect(_on_tier_indicator_draw)
