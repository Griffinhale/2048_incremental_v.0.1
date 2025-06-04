class_name SkillTree
extends RefCounted

## Base upgrade tree class with common mechanics
## Extended by specific tree implementations (Active, Conversion, Generators)

signal upgrade_purchased(upgrade_id: String)
signal tier_unlocked(tier: int)
signal xp_gained(amount: int)

## Core references
var tree_data: UpgradeTreeData
var currency_manager: CurrencyManager
var upgrade_definitions: Dictionary = {}
var active_bonuses: Dictionary = {}

func _init(tree_name: String, currency_mgr: CurrencyManager):
	tree_data = UpgradeTreeData.new()
	tree_data.tree_name = tree_name
	currency_manager = currency_mgr
	
	# Initialize upgrade definitions - to be overridden by child classes
	_initialize_upgrades()
	_calculate_active_bonuses()

## Abstract method - must be implemented by child classes
func _initialize_upgrades() -> void:
	push_error("_initialize_upgrades() must be implemented by child class")

## Core upgrade system methods
func purchase_upgrade(upgrade_id: String) -> bool:
	if not is_upgrade_available(upgrade_id):
		return false
	
	var cost = get_upgrade_cost(upgrade_id)
	var xp_type = _get_xp_currency_type()
	
	if not currency_manager.can_afford(xp_type, cost):
		return false
	
	# Execute purchase
	if currency_manager.spend_currency(xp_type, cost):
		tree_data.purchased_upgrades[upgrade_id] = true
		tree_data.total_xp_invested += cost
		
		# Apply upgrade effects
		_apply_upgrade_effects(upgrade_id)
		_calculate_active_bonuses()
		
		# Check for tier unlocks
		_check_tier_unlocks()
		
		upgrade_purchased.emit(upgrade_id)
		return true
	
	return false

func is_upgrade_available(upgrade_id: String) -> bool:
	# Already purchased
	if tree_data.is_upgrade_purchased(upgrade_id):
		return false
	
	# Upgrade doesn't exist
	if not upgrade_definitions.has(upgrade_id):
		return false
	
	var upgrade_def = upgrade_definitions[upgrade_id]
	
	# Check tier requirement
	var required_tier = upgrade_def.get("tier", 1)
	if required_tier > tree_data.current_tier:
		return false
	
	# Check prerequisite upgrades
	var prerequisites = upgrade_def.get("prerequisites", [])
	for prereq in prerequisites:
		if not tree_data.is_upgrade_purchased(prereq):
			return false
	
	return true

func get_upgrade_cost(upgrade_id: String) -> int:
	if not upgrade_definitions.has(upgrade_id):
		return 0
	
	return upgrade_definitions[upgrade_id].get("cost", 0)

func unlock_tier(tier: int) -> bool:
	if not tree_data.can_unlock_tier(tier):
		return false
	
	tree_data.current_tier = tier
	tier_unlocked.emit(tier)
	return true

func get_tree_bonuses() -> Dictionary:
	return active_bonuses.duplicate()

func get_upgrade_info(upgrade_id: String) -> Dictionary:
	if not upgrade_definitions.has(upgrade_id):
		return {}
	
	var info = upgrade_definitions[upgrade_id].duplicate()
	info["purchased"] = tree_data.is_upgrade_purchased(upgrade_id)
	info["available"] = is_upgrade_available(upgrade_id)
	info["can_afford"] = currency_manager.can_afford(_get_xp_currency_type(), get_upgrade_cost(upgrade_id))
	return info

func reset_tree(preserve_keystones: bool = false) -> void:
	tree_data.reset_tree(preserve_keystones)
	_calculate_active_bonuses()

## XP and progression methods
func gain_xp(amount: int) -> void:
	var xp_type = _get_xp_currency_type()
	currency_manager.add_currency(xp_type, amount)
	xp_gained.emit(amount)

func get_tier_progress(tier: int) -> float:
	return tree_data.get_tier_progress(tier)

func get_available_upgrades() -> Array:
	var available = []
	for upgrade_id in upgrade_definitions.keys():
		if is_upgrade_available(upgrade_id):
			available.append(upgrade_id)
	return available

func get_purchased_upgrades() -> Array:
	var purchased = []
	for upgrade_id in upgrade_definitions.keys():
		if tree_data.is_upgrade_purchased(upgrade_id):
			purchased.append(upgrade_id)
	return purchased

## Protected methods for child classes to override
func _get_xp_currency_type() -> String:
	# Default XP type - override in child classes
	return tree_data.tree_name.to_lower() + "_xp"

func _apply_upgrade_effects(upgrade_id: String) -> void:
	# Override in child classes to apply specific effects
	pass

func _calculate_active_bonuses() -> void:
	# Override in child classes to calculate bonuses
	active_bonuses.clear()

## Private methods
func _check_tier_unlocks() -> void:
	for tier in range(tree_data.current_tier + 1, tree_data.tier_xp_requirements.size()):
		if tree_data.can_unlock_tier(tier):
			unlock_tier(tier)

## Save/load functionality
func save_tree_state() -> Dictionary:
	return tree_data.to_dictionary()

func load_tree_state(data: Dictionary) -> void:
	tree_data.from_dictionary(data)
	_calculate_active_bonuses()

## Utility methods for upgrade definitions
func _create_upgrade_definition(id: String, name: String, description: String, cost: int, tier: int = 1, prerequisites: Array = []) -> Dictionary:
	return {
		"id": id,
		"name": name,
		"description": description,
		"cost": cost,
		"tier": tier,
		"prerequisites": prerequisites
	}

## Debug methods
func get_debug_info() -> Dictionary:
	return {
		"tree_name": tree_data.tree_name,
		"current_tier": tree_data.current_tier,
		"total_xp": tree_data.total_xp_invested,
		"purchased_count": tree_data.purchased_upgrades.size(),
		"available_count": get_available_upgrades().size(),
		"active_bonuses": active_bonuses
	}
