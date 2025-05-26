extends PanelContainer

@onready var content_container: VBoxContainer
@onready var generator_manager := get_node("/root/GeneratorManager")
@onready var stats_tracker := get_node("/root/StatsTracker")

# Debug display flags
var debug_flags := {
	"currencies": true,
	"generators": true,
	"conversion_rates": true,
	"performance": true,
	"algorithms": true,
	"recent_activity": true
}

# UI refresh settings
var refresh_interval := 1.0
var refresh_timer: Timer

# Store labels for efficient updates (instead of recreating them)
var currency_labels := {}
var generator_labels := {}
var conversion_labels := {}
var algorithm_labels := {}
var performance_labels := {}
var activity_labels := {}

var section_containers := {}

func _ready():
	print("DebugPanel _ready() called")
	setup_ui()
	setup_refresh_timer()
	create_debug_sections()
	
	# Debug the panel's visibility and position
	await get_tree().process_frame
	print("DebugPanel - Visible: %s, Position: %s, Size: %s" % [visible, global_position, size])
	print("Content container - Visible: %s, Children count: %d" % [content_container.visible, content_container.get_child_count()])

func setup_ui():
	# Create main container if it doesn't exist
	if not content_container:
		content_container = VBoxContainer.new()
		content_container.name = "DebugContentContainer"
		add_child(content_container)
	
	# Add some visual styling to make containers visible
	add_theme_stylebox_override("panel", create_debug_style())
	content_container.add_theme_constant_override("separation", 5)
	
	# Set up scrolling if the panel gets too long
	if not get_parent() is ScrollContainer:
		print("Note: Consider wrapping DebugPanel in a ScrollContainer for better UX")

func create_debug_style():
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.8)  # Semi-transparent dark background
	style.border_color = Color(0.3, 0.3, 0.3, 1.0)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.content_margin_left = 5
	style.content_margin_right = 5
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	return style

func setup_refresh_timer():
	refresh_timer = Timer.new()
	refresh_timer.wait_time = refresh_interval
	refresh_timer.autostart = true
	refresh_timer.one_shot = false
	refresh_timer.timeout.connect(_on_refresh_timer_timeout)
	add_child(refresh_timer)

func create_debug_sections():
	create_section("Currency Debug", "currencies")
	create_section("Generator Debug", "generators") 
	create_section("Conversion Rates", "conversion_rates")
	create_section("Algorithm Analysis", "algorithms")
	create_section("Performance Metrics", "performance")
	create_section("Recent Activity", "recent_activity")
	
	# Add control buttons
	create_control_section()
	
	# Initialize all labels after sections are created
	initialize_labels()

func create_section(title: String, flag_name: String):
	if not debug_flags.get(flag_name, false):
		return
	
	# Section header
	var header = Label.new()
	header.text = "=== %s ===" % title
	header.add_theme_font_size_override("font_size", 14)
	header.add_theme_color_override("font_color", Color.CYAN)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_container.add_child(header)
	
	# Section container
	var section = VBoxContainer.new()
	section.name = "Section_%s" % flag_name
	section.add_theme_constant_override("separation", 2)
	
	# Add a background to the section for visibility
	var section_style = StyleBoxFlat.new()
	section_style.bg_color = Color(0.05, 0.05, 0.05, 0.5)
	section_style.content_margin_left = 10
	section_style.content_margin_right = 10
	section_style.content_margin_top = 5
	section_style.content_margin_bottom = 5
	section.add_theme_stylebox_override("panel", section_style)
	
	section_containers[flag_name] = section
	content_container.add_child(section)
	
	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	content_container.add_child(spacer)
	
	print("Created section: %s with container: %s" % [title, section.name])

func create_control_section():
	var control_header = Label.new()
	control_header.text = "=== Debug Controls ==="
	control_header.add_theme_font_size_override("font_size", 14)
	content_container.add_child(control_header)
	
	var control_container = HBoxContainer.new()
	content_container.add_child(control_container)
	
	# Reset button
	var reset_button = Button.new()
	reset_button.text = "Reset Tracking"
	reset_button.pressed.connect(_on_reset_tracking_pressed)
	control_container.add_child(reset_button)
	
	# Export button
	var export_button = Button.new()
	export_button.text = "Export Debug Data"
	export_button.pressed.connect(_on_export_debug_pressed)
	control_container.add_child(export_button)

func initialize_labels():
	# Create persistent labels for each section
	initialize_currency_labels()
	initialize_generator_labels()
	initialize_conversion_labels()
	initialize_algorithm_labels()
	initialize_performance_labels()
	initialize_activity_labels()

func initialize_currency_labels():
	if not debug_flags.get("currencies", false):
		return
	
	var section = section_containers.get("currencies")
	if not section:
		print("Currency section not found!")
		return
	
	print("Creating currency labels...")
	
	# Create labels for each currency type
	var currency_types = ["score", "conversion", "xp", "prestige", "apex"]
	for currency_type in currency_types:
		var label = Label.new()
		label.text = "%s: Loading..." % currency_type.capitalize()
		label.visible = true  # Explicitly ensure visibility
		
		# Add some styling to make labels more visible
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_font_size_override("font_size", 12)
		
		# Ensure the label has a minimum size
		label.custom_minimum_size = Vector2(200, 20)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		currency_labels[currency_type] = label
		section.add_child(label)
		print("Created label for: ", currency_type, " with text: ", label.text)
		
		# Debug the label's properties after adding to scene
		await get_tree().process_frame
		print("Label %s - Position: %s, Size: %s, Visible: %s, Parent: %s" % [
			currency_type, 
			label.global_position, 
			label.size, 
			label.visible,
			label.get_parent().name or "No parent"
		])

func initialize_generator_labels():
	if not debug_flags.get("generators", false):
		return
	
	var section = section_containers.get("generators")
	if not section:
		return
	
	# Create a few generator labels (will expand as needed)
	for i in range(5):  # Adjust based on your max generators
		var label = Label.new()
		label.text = "Generator %d: Not initialized" % i
		label.visible = false  # Hide until we have data
		generator_labels["gen_%d" % i] = label
		section.add_child(label)
	
	# Overall total label
	var total_label = Label.new()
	total_label.text = "Overall Generator Output: 0"
	generator_labels["total"] = total_label
	section.add_child(total_label)

func initialize_conversion_labels():
	if not debug_flags.get("conversion_rates", false):
		return
	
	var section = section_containers.get("conversion_rates")
	if not section:
		return
	
	var rate_label = Label.new()
	rate_label.text = "Conversion Rate: 0.000"
	conversion_labels["rate"] = rate_label
	section.add_child(rate_label)
	
	var efficiency_label = Label.new()
	efficiency_label.text = "Conversion Efficiency: 0.000"
	conversion_labels["efficiency"] = efficiency_label
	section.add_child(efficiency_label)
	
	var potential_label = Label.new()
	potential_label.text = "Potential Conversion: 0 → 0"
	conversion_labels["potential"] = potential_label
	section.add_child(potential_label)

func initialize_algorithm_labels():
	if not debug_flags.get("algorithms", false):
		return
	
	var section = section_containers.get("algorithms")
	if not section:
		return
	
	# Create algorithm labels (will be updated based on actual generators)
	for i in range(5):
		var label = Label.new()
		label.text = "Algorithm %d: Not initialized" % i
		label.visible = false
		algorithm_labels["algo_%d" % i] = label
		section.add_child(label)

func initialize_performance_labels():
	if not debug_flags.get("performance", false):
		return
	
	var section = section_containers.get("performance")
	if not section:
		return
	
	var fps_label = Label.new()
	fps_label.text = "FPS: 0"
	performance_labels["fps"] = fps_label
	section.add_child(fps_label)
	
	var memory_label = Label.new()
	memory_label.text = "Memory Usage: 0.00 MB"
	performance_labels["memory"] = memory_label
	section.add_child(memory_label)

func initialize_activity_labels():
	if not debug_flags.get("recent_activity", false):
		return
	
	var section = section_containers.get("recent_activity")
	if not section:
		return
	
	var activity_label = Label.new()
	activity_label.text = "Last Update: Never"
	activity_labels["last_update"] = activity_label
	section.add_child(activity_label)

func _on_refresh_timer_timeout():
	print("Debug panel refresh triggered at: ", Time.get_time_string_from_system())
	update_debug_display()

func update_debug_display():
	update_currency_debug()
	update_generator_debug()
	update_conversion_debug()
	update_algorithm_debug()
	update_performance_debug()
	update_recent_activity_debug()

func update_currency_debug():
	if not debug_flags.get("currencies", false):
		return
	
	# Check if CurrencyManager exists and has the required methods
	if not CurrencyManager:
		for currency_type in currency_labels:
			currency_labels[currency_type].text = "%s: CurrencyManager not found" % currency_type.capitalize()
		return
	
	# Try to get debug info, with error handling
	var debug_info = {}
	if CurrencyManager.has_method("get_all_debug_info"):
		debug_info = CurrencyManager.get_all_debug_info()
	else:
		# Fallback: try to get basic currency info
		for currency_type in currency_labels:
			if CurrencyManager.has_method("get_currency"):
				var amount = CurrencyManager.get_currency(currency_type)
				debug_info[currency_type] = {
					"current_balance": amount,
					"total_earned": 0,
					"total_spent": 0,
					"recent_earned_per_minute": 0.0
				}
	
	print("Debug info retrieved: ", debug_info.keys() or "No data")
	
	for currency_type in currency_labels:
		var label = currency_labels[currency_type]
		if debug_info.has(currency_type):
			var info = debug_info[currency_type]
			if CurrencyManager.has_method("format_currency"):
				label.text = "%s: %s (Earned: %s, Spent: %s, Rate: %.1f/min)" % [
					currency_type.capitalize(),
					CurrencyManager.format_currency(info.current_balance),
					CurrencyManager.format_currency(info.total_earned),
					CurrencyManager.format_currency(info.total_spent),
					info.recent_earned_per_minute
				]
			else:
				label.text = "%s: %.2f (No formatter available)" % [currency_type.capitalize(), info.current_balance]
		else:
			label.text = "%s: No data available" % currency_type.capitalize()

func update_generator_debug():
	if not debug_flags.get("generators", false):
		return
	
	if not generator_manager.has_method("get_debug_summary"):
		# Show error in first generator label
		if generator_labels.has("gen_0"):
			generator_labels["gen_0"].text = "Generator debug not available - update GeneratorManager"
			generator_labels["gen_0"].visible = true
		return
	
	var generator_debug = generator_manager.get_debug_summary()
	
	# Hide all generator labels first
	for key in generator_labels:
		if key.begins_with("gen_"):
			generator_labels[key].visible = false
	
	# Update visible generators
	var gen_index = 0
	for gen_id in generator_debug:
		if gen_id == "overall_total":
			continue
		
		var label_key = "gen_%d" % gen_index
		if generator_labels.has(label_key):
			var info = generator_debug[gen_id]
			var label = generator_labels[label_key]
			label.text = "%s: Total: %s, Ticks: %d, Avg: %.3f" % [
				gen_id,
				CurrencyManager.format_currency(info.total_yield),
				info.tick_count,
				info.average_yield
			]
			label.visible = true
		gen_index += 1
	
	# Update overall total
	if generator_labels.has("total"):
		generator_labels["total"].text = "Overall Generator Output: %s" % CurrencyManager.format_currency(generator_debug.get("overall_total", 0.0))

func update_conversion_debug():
	if not debug_flags.get("conversion_rates", false):
		return
	
	if conversion_labels.has("rate"):
		if CurrencyManager.has_method("get_conversion_rate"):
			conversion_labels["rate"].text = "Conversion Rate: %.3f" % CurrencyManager.get_conversion_rate()
		else:
			conversion_labels["rate"].text = "Conversion Rate: Method not found"
	
	if conversion_labels.has("efficiency"):
		if CurrencyManager.has_method("get_conversion_efficiency"):
			conversion_labels["efficiency"].text = "Conversion Efficiency: %.3f" % CurrencyManager.get_conversion_efficiency()
		else:
			conversion_labels["efficiency"].text = "Conversion Efficiency: Method not found"
	
	if conversion_labels.has("potential"):
		if CurrencyManager.has_method("get_currency") and CurrencyManager.has_method("get_conversion_rate") and CurrencyManager.has_method("get_conversion_efficiency"):
			var score_currency = CurrencyManager.get_currency("score")
			var potential_conversion = score_currency * CurrencyManager.get_conversion_rate() * CurrencyManager.get_conversion_efficiency()
			if CurrencyManager.has_method("format_currency"):
				conversion_labels["potential"].text = "Potential Conversion: %s → %s" % [
					CurrencyManager.format_currency(score_currency),
					CurrencyManager.format_currency(potential_conversion)
				]
			else:
				conversion_labels["potential"].text = "Potential Conversion: %.2f → %.2f" % [score_currency, potential_conversion]
		else:
			conversion_labels["potential"].text = "Potential Conversion: Methods not available"

func update_algorithm_debug():
	if not debug_flags.get("algorithms", false):
		return
	
	if not generator_manager.has_method("get_debug_summary"):
		return
	
	var generator_debug = generator_manager.get_debug_summary()
	
	# Hide all algorithm labels first
	for key in algorithm_labels:
		algorithm_labels[key].visible = false
	
	var algo_index = 0
	for gen_id in generator_debug:
		if gen_id == "overall_total":
			continue
		
		var info = generator_debug[gen_id]
		if info.has("algorithm"):
			var label_key = "algo_%d" % algo_index
			if algorithm_labels.has(label_key):
				var algorithm_info = info.algorithm
				var label = algorithm_labels[label_key]
				label.text = "%s: Algorithm: %s (Seed: %d)" % [
					gen_id,
					algorithm_info.get("algorithm", "unknown"),
					algorithm_info.get("seed", 0)
				]
				label.visible = true
		algo_index += 1

func update_performance_debug():
	if not debug_flags.get("performance", false):
		return
	
	if performance_labels.has("fps"):
		performance_labels["fps"].text = "FPS: %d" % Engine.get_frames_per_second()
	
	if performance_labels.has("memory"):
		performance_labels["memory"].text = "Memory Usage: %.2f MB" % (OS.get_static_memory_usage() / 1024.0 / 1024.0)

func update_recent_activity_debug():
	if not debug_flags.get("recent_activity", false):
		return
	
	if activity_labels.has("last_update"):
		activity_labels["last_update"].text = "Last Update: %s" % Time.get_datetime_string_from_system()

# Control button handlers
func _on_reset_tracking_pressed():
	CurrencyManager.reset_debug_tracking()
	if generator_manager.has_method("reset_debug_data"):
		generator_manager.reset_debug_data()
	print("Debug tracking data reset")

func _on_export_debug_pressed():
	var debug_data = {
		"timestamp": Time.get_datetime_string_from_system(),
		"currencies": CurrencyManager.get_all_debug_info(),
		"generators": generator_manager.get_debug_summary() if generator_manager.has_method("get_debug_summary") else {}
	}
	
	# In a real implementation, you'd save this to a file
	print("Debug data exported:")
	print(JSON.stringify(debug_data, "\t"))

# Public methods for toggling debug sections
func toggle_debug_section(section_name: String, enabled: bool):
	if debug_flags.has(section_name):
		debug_flags[section_name] = enabled
		# Recreate the entire display
		rebuild_debug_panel()

func rebuild_debug_panel():
	# Clear everything
	for child in content_container.get_children():
		child.queue_free()
	
	# Clear label references
	currency_labels.clear()
	generator_labels.clear()
	conversion_labels.clear()
	algorithm_labels.clear()
	performance_labels.clear()
	activity_labels.clear()
	section_containers.clear()
	
	# Wait a frame for cleanup, then recreate
	await get_tree().process_frame
	create_debug_sections()

func set_refresh_rate(rate: float):
	refresh_interval = max(0.1, rate)  # Minimum 0.1 second refresh
	refresh_timer.wait_time = refresh_interval
