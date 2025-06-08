extends Node

## Central upgrade system coordinator managing all six upgrade trees
## Handles tree initialization, purchase coordination, and bonus aggregation
## Autoloaded singleton for global access

signal upgrade_purchased(tree_name: String, upgrade_id: String)
signal tier_unlocked(tree_name: String, tier: int)
signal tree_reset(tree_name: String)
signal bonuses_updated()

## Tree instances - only implementing the first three for now
var active_tree: ActiveTree
var conversion_tree: ConversionTree
var generators_tree: GeneratorsTree

## Future trees (placeholders for v0.6+)
var discipline_tree  # ChallengeTree - for Discipline/Challenge system
#var reset_tree       # ResetTree - for prestige/reset mechanics  
var lore_tree        # LoreTree - for information systems

## Manager references
var currency_manager: CurrencyManager
var generator_manager: GeneratorManager

## Aggregated bonuses for easy access
var all_bonuses: Dictionary = {}
var tree_statuses: Dictionary = {}

	
func _ready():
	# Wait for other autoloaded managers to initialize
	#await get_tree().process_frame
	_initialize_upgrade_system()


func _initialize_upgrade_system():
	# Get manager references
	currency_manager = get_node("/root/CurrencyManager")
	generator_manager = get_node("/root/GeneratorManager")
	
	if not currency_manager:
		push_error("UpgradeManager: CurrencyManager not found")
		return
	
	if not generator_manager:
		push_error("UpgradeManager: GeneratorManager not found")
		return
	
	# Initialize XP currencies in CurrencyManager
	_setup_xp_currencies()
	
	# Create upgrade trees
	_create_upgrade_trees()
	
	# Connect tree signals
	_connect_tree_signals()
	
	# Initial bonus calculation
	_update_all_bonuses()
	
	print("UpgradeManager: Upgrade system initialized with 3 trees")

func _setup_xp_currencies():
	# Add XP currency types to the currency manager
	currency_manager.add_currency("active_xp", 0)
	currency_manager.add_currency("conversion_xp", 0) 
	currency_manager.add_currency("generator_xp", 0)
	
	# Future XP types for remaining trees
	currency_manager.add_currency("discipline_xp", 0)
	currency_manager.add_currency("reset_xp", 0)
	currency_manager.add_currency("lore_xp", 0)

func _create_upgrade_trees():
	# Create the three core trees
	active_tree = ActiveTree.new(currency_manager)
	conversion_tree = ConversionTree.new(currency_manager)
	generators_tree = GeneratorsTree.new(currency_manager)
	
	# Store trees in a dictionary for easy access
	tree_statuses = {
		"Active": {"tree": active_tree, "unlocked": true},
		"Conversion": {"tree": conversion_tree, "unlocked": true}, 
		"Generators": {"tree": generators_tree, "unlocked": true},
		"Discipline": {"tree": null, "unlocked": false},
		"Reset": {"tree": null, "unlocked": false},
		"Lore": {"tree": null, "unlocked": false}
	}

func _connect_tree_signals():
	# Connect signals from all active trees
	for tree_name in tree_statuses.keys():
		var tree_data = tree_statuses[tree_name]
		if tree_data["tree"] != null:
			var tree = tree_data["tree"]
			tree.upgrade_purchased.connect(_on_upgrade_purchased.bind(tree_name))
			tree.tier_unlocked.connect(_on_tier_unlocked.bind(tree_name))
			tree.xp_gained.connect(_on_xp_gained.bind(tree_name))

## Core upgrade system methods
func purchase_upgrade(tree_name: String, upgrade_id: String) -> bool:
	var tree = get_tree_instance(tree_name)
	if not tree:
		push_error("UpgradeManager: Tree not found: " + tree_name)
		return false
	
	if tree.purchase_upgrade(upgrade_id):
		_update_all_bonuses()
		return true
	
	return false

func is_upgrade_available(tree_name: String, upgrade_id: String) -> bool:
	var tree = get_tree_instance(tree_name)
	if not tree:
		return false
	
	return tree.is_upgrade_available(upgrade_id)

func get_upgrade_cost(tree_name: String, upgrade_id: String) -> int:
	var tree = get_tree_instance(tree_name)
	if not tree:
		return 0
	
	return tree.get_upgrade_cost(upgrade_id)

func get_upgrade_info(tree_name: String, upgrade_id: String) -> Dictionary:
	var tree = get_tree_instance(tree_name)
	if not tree:
		return {}
	
	return tree.get_upgrade_info(upgrade_id)

## Tree management methods
func get_tree_instance(tree_name: String):
	if not tree_statuses.has(tree_name):
		return null
	
	return tree_statuses[tree_name]["tree"]

func is_tree_unlocked(tree_name: String) -> bool:
	if not tree_statuses.has(tree_name):
		return false
	
	return tree_statuses[tree_name]["unlocked"]

func get_available_trees() -> Array:
	var available = []
	for tree_name in tree_statuses.keys():
		if tree_statuses[tree_name]["unlocked"] and tree_statuses[tree_name]["tree"] != null:
			available.append(tree_name)
	return available

func unlock_tree(tree_name: String) -> bool:
	if not tree_statuses.has(tree_name):
		return false
	
	if tree_statuses[tree_name]["unlocked"]:
		return true  # Already unlocked
	
	tree_statuses[tree_name]["unlocked"] = true
	# TODO: Create tree instance when implemented
	print("UpgradeManager: Tree unlocked: " + tree_name)
	return true

## Bonus aggregation and access methods
func get_tree_bonuses(tree_name: String) -> Dictionary:
	var tree = get_tree_instance(tree_name)
	if not tree:
		return {}
	
	return tree.get_tree_bonuses()

func get_global_bonuses() -> Dictionary:
	return all_bonuses.duplicate()

func get_active_play_bonuses() -> Dictionary:
	return get_tree_bonuses("Active")

func get_conversion_bonuses() -> Dictionary:
	return get_tree_bonuses("Conversion")

func get_generator_bonuses() -> Dictionary:
	return get_tree_bonuses("Generators")

## Specific bonus calculation methods for manager integration
func calculate_move_score_bonus(base_score: int, move_count: int, tiles_merged: int) -> float:
	if active_tree:
		return active_tree.calculate_move_score_bonus(base_score, move_count, tiles_merged)
	return 1.0

func calculate_conversion_multiplier(game_score: int, games_in_batch: int = 1) -> float:
	if conversion_tree:
		return conversion_tree.calculate_conversion_multiplier(game_score, games_in_batch)
	return 1.0

func calculate_generator_yield_multiplier(generator_data: GeneratorData, active_generator_count: int, board_tiles: Array = []) -> float:
	if generators_tree:
		return generators_tree.calculate_generator_yield_multiplier(generator_data, active_generator_count, board_tiles)
	return 1.0

func calculate_generator_frequency_multiplier() -> float:
	if generators_tree:
		return generators_tree.calculate_generator_frequency_multiplier()
	return 1.0

## XP distribution methods
func award_active_xp(amount: int) -> void:
	currency_manager.add_currency("active_xp", amount)

func award_conversion_xp(amount: int) -> void:
	currency_manager.add_currency("conversion_xp", amount)

func award_generator_xp(amount: int) -> void:
	currency_manager.add_currency("generator_xp", amount)

## Integration helper methods for game events
func on_move_completed(score_gained: int, tiles_merged: int, move_count: int) -> void:
	# Award active XP and let the tree handle internal logic
	if active_tree:
		active_tree.gain_xp_from_move(score_gained, tiles_merged)

func on_game_completed(final_score: int, moves_made: int, max_tile: int) -> void:
	# Award active XP for game completion
	if active_tree:
		active_tree.gain_xp_from_game_completion(final_score, moves_made, max_tile)

func on_conversion_completed(converted_amount: float, games_converted: int) -> void:
	# Award conversion XP
	if conversion_tree:
		conversion_tree.gain_xp_from_conversion(converted_amount, games_converted)

func on_generator_yield(yield_amount: float, generator_count: int) -> void:
	# Award generator XP
	if generators_tree:
		generators_tree.gain_xp_from_generator_yield(yield_amount, generator_count)

func on_generator_upgraded(upgrade_cost: float) -> void:
	# Award generator XP for upgrades
	if generators_tree:
		generators_tree.gain_xp_from_generator_upgrade(upgrade_cost)

## Queue system integration (for Active tree)
func is_queue_unlocked() -> bool:
	if active_tree:
		return active_tree.is_queue_unlocked()
	return false

func get_queue_length() -> int:
	if active_tree:
		return active_tree.get_queue_length()
	return 0

## Conversion system integration
func is_detailed_tracking_enabled() -> bool:
	if conversion_tree:
		return conversion_tree.is_detailed_tracking_enabled()
	return false

func get_optimization_hints(recent_conversions: Array) -> Array:
	if conversion_tree:
		return conversion_tree.generate_optimization_hints(recent_conversions)
	return []

## Generator system integration
func is_targeting_enabled() -> bool:
	if generators_tree:
		return generators_tree.is_targeting_enabled()
	return false

func calculate_targeting_effectiveness(generator_data: GeneratorData, board_tiles: Array) -> float:
	if generators_tree:
		return generators_tree.calculate_targeting_effectiveness(generator_data, board_tiles)
	return 0.0

## Prestige/Reset system (for future Reset tree)
func reset_tree(tree_name: String, preserve_keystones: bool = false) -> bool:
	var tree = get_tree_instance(tree_name)
	if not tree:
		return false
	
	tree.reset_tree(preserve_keystones)
	_update_all_bonuses()
	tree_reset.emit(tree_name)
	return true

func reset_all_trees(preserve_keystones: bool = false) -> void:
	for tree_name in get_available_trees():
		reset_tree(tree_name, preserve_keystones)

## Save/Load system
func save_upgrade_state() -> Dictionary:
	var save_data = {
		"tree_statuses": {},
		"version": "0.3"  # For future compatibility
	}
	
	for tree_name in tree_statuses.keys():
		var tree_data = tree_statuses[tree_name]
		save_data["tree_statuses"][tree_name] = {
			"unlocked": tree_data["unlocked"]
		}
		
		if tree_data["tree"] != null:
			save_data["tree_statuses"][tree_name]["tree_data"] = tree_data["tree"].save_tree_state()
	
	return save_data

func load_upgrade_state(save_data: Dictionary) -> void:
	if not save_data.has("tree_statuses"):
		return
	
	var loaded_statuses = save_data["tree_statuses"]
	
	for tree_name in loaded_statuses.keys():
		if tree_statuses.has(tree_name):
			var loaded_tree = loaded_statuses[tree_name]
			tree_statuses[tree_name]["unlocked"] = loaded_tree.get("unlocked", false)
			
			if loaded_tree.has("tree_data") and tree_statuses[tree_name]["tree"] != null:
				tree_statuses[tree_name]["tree"].load_tree_state(loaded_tree["tree_data"])
	
	_update_all_bonuses()

## Private methods
func _update_all_bonuses() -> void:
	all_bonuses.clear()
	
	# Aggregate bonuses from all trees
	for tree_name in get_available_trees():
		var tree_bonuses = get_tree_bonuses(tree_name)
		for bonus_key in tree_bonuses.keys():
			# Prefix with tree name to avoid conflicts
			var global_key = tree_name.to_lower() + "_" + bonus_key
			all_bonuses[global_key] = tree_bonuses[bonus_key]
	
	bonuses_updated.emit()

## Signal handlers
func _on_upgrade_purchased(tree_name: String, upgrade_id: String) -> void:
	upgrade_purchased.emit(tree_name, upgrade_id)
	print("UpgradeManager: Upgrade purchased - " + tree_name + ":" + upgrade_id)

func _on_tier_unlocked(tree_name: String, tier: int) -> void:
	tier_unlocked.emit(tree_name, tier)
	print("UpgradeManager: Tier unlocked - " + tree_name + " Tier " + str(tier))

func _on_xp_gained(tree_name: String, amount: int) -> void:
	# XP gain is handled by the trees themselves, just log for debug
	pass

## Debug and utility methods
func get_upgrade_system_stats() -> Dictionary:
	var stats = {
		"available_trees": get_available_trees().size(),
		"total_trees": tree_statuses.size(),
		"total_bonuses": all_bonuses.size(),
		"tree_details": {}
	}
	
	for tree_name in get_available_trees():
		var tree = get_tree_instance(tree_name)
		if tree:
			stats["tree_details"][tree_name] = tree.get_debug_info()
	
	return stats

func get_all_available_upgrades() -> Dictionary:
	var all_upgrades = {}
	
	for tree_name in get_available_trees():
		var tree = get_tree_instance(tree_name)
		if tree:
			all_upgrades[tree_name] = tree.get_available_upgrades()
	
	return all_upgrades

func get_xp_balances() -> Dictionary:
	return {
		"active_xp": currency_manager.get_currency("active_xp"),
		"conversion_xp": currency_manager.get_currency("conversion_xp"),
		"generator_xp": currency_manager.get_currency("generator_xp"),
		"discipline_xp": currency_manager.get_currency("discipline_xp"),
		"reset_xp": currency_manager.get_currency("reset_xp"),
		"lore_xp": currency_manager.get_currency("lore_xp")
	}
