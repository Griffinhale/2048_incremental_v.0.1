extends Control
class_name TreeWidget

## Individual upgrade tree widget with expandable upgrade display
## Displays tree status, handles clicks for expansion, and supports drag-and-drop

signal tree_clicked(tree_name: String)
signal tree_expanded(tree_name: String)
signal tree_collapsed(tree_name: String)
signal tree_drag_started(tree_name: String)
signal tree_dropped(tree_name: String, zone_name: String)

## Tree data
@export var tree_name: String
var upgrade_manager: UpgradeManager
var tree_instance: SkillTree

## UI state
var is_selected: bool = false
var is_expanded: bool = false
var is_dragging: bool = false
var drag_offset: Vector2

## Visual configuration
var base_size: Vector2 = Vector2(100, 80)
var selected_size: Vector2 = Vector2(120, 100)
var expanded_size: Vector2 = Vector2(300, 400)

## UI Elements - created dynamically
var main_container: VBoxContainer
var compact_view: Control
var expanded_view: Control
var background_panel: Panel
var tree_icon: Control
var tree_label: Label
var tier_indicator: Control
var progress_bar: ProgressBar
var expand_button: Button

## Expansion components
var upgrade_scroll: ScrollContainer
var upgrade_container: VBoxContainer

func _ready():
	_setup_ui()
	_setup_input_handling()
	CurrencyManager.currency_changed.connect(_on_currency_change)
	await get_tree().process_frame

func _on_currency_change(currency_type: String, currency_amt: float):
	if currency_type == tree_name:
		_update_expanded_header()

func _setup_ui():
	# Set initial size
	custom_minimum_size = base_size
	size = base_size
	
	# Create background panel
	background_panel = Panel.new()
	background_panel.name = "Background"
	background_panel.anchors_preset = Control.PRESET_FULL_RECT
	add_child(background_panel)
	
	# Main container for all content
	main_container = VBoxContainer.new()
	main_container.name = "MainContainer"
	main_container.anchors_preset = Control.PRESET_FULL_RECT
	main_container.add_theme_constant_override("separation", 5)
	add_child(main_container)
	
	# Create compact view (always visible)
	_create_compact_view()
	
	# Create expanded view (hidden initially)
	_create_expanded_view()
	
	# Start in compact mode
	expanded_view.visible = false

func _create_compact_view():
	compact_view = VBoxContainer.new()
	compact_view.name = "CompactView"
	compact_view.add_theme_constant_override("separation", 2)
	main_container.add_child(compact_view)
	
	# Tree icon/visual (the colored rectangle)
	tree_icon = Control.new()
	tree_icon.name = "TreeIcon"
	tree_icon.custom_minimum_size = Vector2(60, 40)
	tree_icon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tree_icon.draw.connect(_on_tree_icon_draw)
	compact_view.add_child(tree_icon)
	
	# Tree name label with expand button
	var header_container = HBoxContainer.new()
	header_container.alignment = BoxContainer.ALIGNMENT_CENTER
	compact_view.add_child(header_container)
	
	tree_label = Label.new()
	tree_label.name = "TreeLabel"
	tree_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tree_label.add_theme_font_size_override("font_size", 10)
	tree_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tree_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_container.add_child(tree_label)
	
	# Small expand/collapse button
	expand_button = Button.new()
	expand_button.name = "ExpandButton"
	expand_button.text = "+"
	expand_button.custom_minimum_size = Vector2(16, 16)
	expand_button.add_theme_font_size_override("font_size", 10)
	expand_button.pressed.connect(_toggle_expansion)
	header_container.add_child(expand_button)
	
	# Tier indicator (small visual indicator)
	tier_indicator = Control.new()
	tier_indicator.name = "TierIndicator"
	tier_indicator.custom_minimum_size = Vector2(50, 8)
	tier_indicator.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tier_indicator.draw.connect(_on_tier_indicator_draw)
	compact_view.add_child(tier_indicator)
	
	# XP progress (tiny progress bar)
	progress_bar = ProgressBar.new()
	progress_bar.name = "ProgressBar"
	progress_bar.custom_minimum_size = Vector2(60, 6)
	progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_bar.show_percentage = false
	compact_view.add_child(progress_bar)

func _create_expanded_view():
	expanded_view = VBoxContainer.new()
	expanded_view.name = "ExpandedView"
	expanded_view.add_theme_constant_override("separation", 10)
	main_container.add_child(expanded_view)
	
	# Tree info header
	var info_header = _create_tree_info_header()
	expanded_view.add_child(info_header)
	
	# Scrollable upgrade list
	upgrade_scroll = ScrollContainer.new()
	upgrade_scroll.name = "UpgradeScroll"
	upgrade_scroll.custom_minimum_size = Vector2(280, 250)
	upgrade_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	expanded_view.add_child(upgrade_scroll)
	
	upgrade_container = VBoxContainer.new()
	upgrade_container.name = "UpgradeContainer"
	upgrade_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	upgrade_container.add_theme_constant_override("separation", 5)
	upgrade_scroll.add_child(upgrade_container)

func _create_tree_info_header() -> Control:
	var header = VBoxContainer.new()
	header.add_theme_constant_override("separation", 5)
	
	# Current tier and XP
	var stats_container = HBoxContainer.new()
	header.add_child(stats_container)
	
	var tier_label = Label.new()
	tier_label.text = "Tier: 1"
	tier_label.name = "TierLabel"
	tier_label.add_theme_font_size_override("font_size", 12)
	stats_container.add_child(tier_label)
	
	var xp_label = Label.new()
	xp_label.text = "XP: 0"
	xp_label.name = "XPLabel"
	xp_label.add_theme_font_size_override("font_size", 12)
	xp_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stats_container.add_child(xp_label)
	
	# Next tier progress (if applicable)
	var progress_container = VBoxContainer.new()
	progress_container.name = "ProgressContainer"
	header.add_child(progress_container)
	
	return header

func _setup_input_handling():
	# Enable mouse input
	mouse_filter = Control.MOUSE_FILTER_PASS

func setup_tree(p_tree_name: String, p_upgrade_manager: UpgradeManager):
	print("Setting up tree: ", p_tree_name)
	tree_name = p_tree_name
	upgrade_manager = p_upgrade_manager
	
	if not upgrade_manager:
		push_error("TreeWidget: UpgradeManager is null")
		return
		
	tree_instance = upgrade_manager.get_tree_instance(tree_name)
	
	if not tree_instance:
		push_error("TreeWidget: Could not find tree instance for " + tree_name)
		return
	
	# Set up visual appearance
	if tree_label:
		_update_tree_display()
		_update_tree_styling()

func _toggle_expansion():
	is_expanded = !is_expanded
	
	if is_expanded:
		_expand_widget()
	else:
		_collapse_widget()

func _expand_widget():
	is_expanded = true
	expand_button.text = "-"
	expanded_view.visible = true
	
	# Update expanded content
	_populate_expanded_view()
	
	# Animate size change
	var tween = create_tween()
	tween.tween_property(self, "custom_minimum_size", expanded_size, 0.3)
	tween.parallel().tween_property(self, "size", expanded_size, 0.3)
	tween.set_ease(Tween.EASE_OUT)
	
	tree_expanded.emit(tree_name)

func _collapse_widget():
	is_expanded = false
	expand_button.text = "+"
	expanded_view.visible = false
	
	# Animate size change back to compact
	var target_size = selected_size if is_selected else base_size
	var tween = create_tween()
	tween.tween_property(self, "custom_minimum_size", target_size, 0.3)
	tween.parallel().tween_property(self, "size", target_size, 0.3)
	tween.set_ease(Tween.EASE_OUT)
	
	tree_collapsed.emit(tree_name)

func _populate_expanded_view():
	if not tree_instance:
		return
	
	# Clear existing content
	for child in upgrade_container.get_children():
		child.queue_free()
	
	# Update header info
	_update_expanded_header()
	
	# Populate upgrades by tier
	for tier in range(1, 4):
		_add_tier_section(tier)

func _update_expanded_header():
	var tier_label = expanded_view.get_node("VBoxContainer/HBoxContainer/TierLabel")
	var xp_label = expanded_view.get_node("VBoxContainer/HBoxContainer/XPLabel")
	var progress_container = expanded_view.get_node("VBoxContainer/ProgressContainer")
	
	if tier_label:
		tier_label.text = "Tier: " + str(tree_instance.tree_data.current_tier)
	
	if xp_label and tree_instance:
		var xp_type = tree_instance._get_xp_currency_type()
		var current_xp = upgrade_manager.currency_manager.get_currency(xp_type)
		xp_label.text = "XP: " + str(int(current_xp))
	
	# Update next tier progress
	if progress_container:
		# Clear existing progress widgets
		for child in progress_container.get_children():
			child.queue_free()
		
		var next_tier = tree_instance.tree_data.current_tier + 1
		if next_tier <= 3:
			var progress = tree_instance.get_tier_progress(next_tier)
			
			var progress_label = Label.new()
			progress_label.text = "Next Tier Progress: " + str(int(progress * 100)) + "%"
			progress_label.add_theme_font_size_override("font_size", 10)
			progress_container.add_child(progress_label)
			
			var tier_progress_bar = ProgressBar.new()
			tier_progress_bar.value = progress * 100
			tier_progress_bar.custom_minimum_size = Vector2(200, 16)
			progress_container.add_child(tier_progress_bar)

func _add_tier_section(tier: int):
	# Tier header
	var tier_header = Label.new()
	tier_header.text = "Tier " + str(tier) + " Upgrades"
	tier_header.add_theme_font_size_override("font_size", 14)
	tier_header.add_theme_color_override("font_color", _get_tier_header_color(tier))
	upgrade_container.add_child(tier_header)
	
	# Get upgrades for this tier
	var tier_upgrades = _get_tier_upgrades(tier)
	
	if tier_upgrades.is_empty():
		var no_upgrades_label = Label.new()
		no_upgrades_label.text = "  No upgrades available"
		no_upgrades_label.modulate = Color.GRAY
		no_upgrades_label.add_theme_font_size_override("font_size", 10)
		upgrade_container.add_child(no_upgrades_label)
	else:
		for upgrade_id in tier_upgrades:
			var upgrade_button = _create_compact_upgrade_button(upgrade_id)
			upgrade_container.add_child(upgrade_button)
	
	# Add separator
	var separator = HSeparator.new()
	separator.modulate = Color(0.5, 0.5, 0.5, 0.7)
	upgrade_container.add_child(separator)

func _get_tier_upgrades(tier: int) -> Array:
	var tier_upgrades = []
	
	if not tree_instance:
		return tier_upgrades
	
	for upgrade_id in tree_instance.upgrade_definitions.keys():
		var upgrade_def = tree_instance.upgrade_definitions[upgrade_id]
		if upgrade_def.get("tier", 1) == tier:
			tier_upgrades.append(upgrade_id)
	
	return tier_upgrades

func _create_compact_upgrade_button(upgrade_id: String) -> Control:
	var upgrade_info = upgrade_manager.get_upgrade_info(tree_name, upgrade_id)
	
	var button_container = VBoxContainer.new()
	button_container.add_theme_constant_override("separation", 2)
	
	# Main upgrade button
	var upgrade_button = Button.new()
	upgrade_button.custom_minimum_size = Vector2(260, 40)
	upgrade_button.disabled = not upgrade_info.get("available", false) or not upgrade_info.get("can_afford", false)
	
	# Button text with name, cost, and status
	var button_text = upgrade_info.get("name", upgrade_id)
	if upgrade_info.get("purchased", false):
		button_text += " ✓"
		upgrade_button.disabled = true
		upgrade_button.modulate = Color(0.8, 1.0, 0.8)  # Light green tint for purchased
	else:
		button_text += " (" + str(upgrade_info.get("cost", 0)) + " XP)"
	
	upgrade_button.text = button_text
	upgrade_button.add_theme_font_size_override("font_size", 10)
	upgrade_button.pressed.connect(_on_upgrade_button_pressed.bind(upgrade_id))
	
	button_container.add_child(upgrade_button)
	
	# Compact description
	var description = upgrade_info.get("description", "")
	if description != "":
		var desc_label = Label.new()
		desc_label.text = description
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_label.add_theme_font_size_override("font_size", 8)
		desc_label.modulate = Color(0.8, 0.8, 0.8)
		desc_label.custom_minimum_size = Vector2(260, 0)
		button_container.add_child(desc_label)
	
	return button_container

func _get_tier_header_color(tier: int) -> Color:
	match tier:
		1:
			return Color.CYAN
		2:
			return Color.YELLOW
		3:
			return Color.ORANGE
		_:
			return Color.WHITE

func _on_upgrade_button_pressed(upgrade_id: String):
	upgrade_manager.purchase_upgrade(tree_name, upgrade_id)
	# Refresh the expanded view to show updated state
	if is_expanded:
		_populate_expanded_view()

func _update_tree_display():
	if not tree_instance or not tree_label:
		return
	
	# Update tree name
	tree_label.text = tree_name
	
	# Update tier indicator
	_update_tier_indicator()
	
	# Update progress bar
	_update_progress_display()
	
	# Update icon styling
	_update_icon_styling()
	
	# If expanded, update expanded content too
	if is_expanded:
		_populate_expanded_view()

func _update_tier_indicator():
	if tier_indicator:
		tier_indicator.queue_redraw()

func _update_progress_display():
	if not progress_bar or not tree_instance:
		return
		
	var next_tier = tree_instance.tree_data.current_tier + 1
	if next_tier <= 3:
		var progress = tree_instance.get_tier_progress(next_tier)
		progress_bar.value = progress * 100
		progress_bar.visible = true
	else:
		progress_bar.visible = false

func _update_icon_styling():
	if tree_icon:
		tree_icon.queue_redraw()

func _update_tree_styling():
	if not background_panel:
		return
		
	var style = _create_tree_style()
	background_panel.add_theme_stylebox_override("panel", style)

func _create_tree_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	
	# Base colors based on tree type
	var base_color = _get_tree_color()
	var border_color = base_color.darkened(0.3)
	
	# Adjust for different states
	if is_expanded:
		base_color = base_color.lightened(0.1)
		border_color = Color.WHITE
	elif is_selected:
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
	
	# Add shadow effect for expanded or selected state
	if is_expanded or is_selected:
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
	
	# Only animate size if not expanded
	if not is_expanded:
		var tween = create_tween()
		var target_size = selected_size if selected else base_size
		tween.tween_property(self, "custom_minimum_size", target_size, 0.2)
		tween.parallel().tween_property(self, "size", target_size, 0.2)

func refresh_state():
	_update_tree_display()

## Custom drawing for tree icon and tier indicator
func _on_tree_icon_draw():
	if not tree_instance or not tree_icon:
		return
		
	# Draw the main tree visualization
	var icon_rect = tree_icon.get_rect()
	var color = _get_tree_color().darkened(0.2)
	
	# Draw main rectangle
	tree_icon.draw_rect(icon_rect, color)
	
	# Draw tier lines
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
	if not tree_instance or not tier_indicator:
		return
		
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
				# Check if clicking on compact view area (not expanded area)
				if not is_expanded or _is_click_in_compact_area(event.position):
					_start_interaction(event.position)
			else:
				_end_interaction(event.position)
	
	elif event is InputEventMouseMotion and is_dragging:
		_handle_drag(event.position)

func _is_click_in_compact_area(position: Vector2) -> bool:
	if not compact_view:
		return true
	
	var compact_rect = compact_view.get_rect()
	return compact_rect.has_point(position)

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
	# Only allow dragging if not expanded
	if not is_expanded:
		is_dragging = true
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
		"keystone_unlocked": tree_instance.tree_data.keystone_unlocked,
		"is_expanded": is_expanded
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
