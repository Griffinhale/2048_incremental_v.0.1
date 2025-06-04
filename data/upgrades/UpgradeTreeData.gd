class_name UpgradeTreeData
extends Resource

## Base upgrade tree data container for persistent state management
## Handles XP tracking, tier unlocks, and upgrade purchase status

## Core tree identification
@export var tree_name: String = ""
@export var current_tier: int = 1
@export var keystone_unlocked: bool = false
@export var enhanced_keystone_unlocked: bool = false

## XP and progression tracking
@export var total_xp_invested: int = 0
@export var tier_xp_requirements: Array[int] = [0, 100, 500, 2000]  # Index 0 unused, tiers 1-3
@export var purchased_upgrades: Dictionary = {}  # upgrade_id -> purchase_status

## Save/load functionality
func to_dictionary() -> Dictionary:
	return {
		"tree_name": tree_name,
		"current_tier": current_tier,
		"keystone_unlocked": keystone_unlocked,
		"enhanced_keystone_unlocked": enhanced_keystone_unlocked,
		"total_xp_invested": total_xp_invested,
		"tier_xp_requirements": tier_xp_requirements,
		"purchased_upgrades": purchased_upgrades
	}

func from_dictionary(data: Dictionary) -> void:
	tree_name = data.get("tree_name", "")
	current_tier = data.get("current_tier", 1)
	keystone_unlocked = data.get("keystone_unlocked", false)
	enhanced_keystone_unlocked = data.get("enhanced_keystone_unlocked", false)
	total_xp_invested = data.get("total_xp_invested", 0)
	tier_xp_requirements = data.get("tier_xp_requirements", [0, 100, 500, 2000])
	purchased_upgrades = data.get("purchased_upgrades", {})

## Validation and utility methods
func is_upgrade_purchased(upgrade_id: String) -> bool:
	return purchased_upgrades.get(upgrade_id, false)

func get_tier_progress(tier: int) -> float:
	if tier <= current_tier:
		return 1.0
	if tier > tier_xp_requirements.size() - 1:
		return 0.0
	
	var required_xp = tier_xp_requirements[tier]
	if required_xp <= 0:
		return 1.0
	
	return min(1.0, float(total_xp_invested) / float(required_xp))

func can_unlock_tier(tier: int) -> bool:
	if tier <= current_tier:
		return false
	if tier > tier_xp_requirements.size() - 1:
		return false
	
	return total_xp_invested >= tier_xp_requirements[tier]

func get_purchased_upgrades_in_tier(tier: int) -> Array:
	var tier_upgrades = []
	for upgrade_id in purchased_upgrades.keys():
		if purchased_upgrades[upgrade_id] and upgrade_id.begins_with("t" + str(tier) + "_"):
			tier_upgrades.append(upgrade_id)
	return tier_upgrades

func reset_tree(preserve_keystones: bool = false) -> void:
	current_tier = 1
	total_xp_invested = 0
	purchased_upgrades.clear()
	
	if not preserve_keystones:
		keystone_unlocked = false
		enhanced_keystone_unlocked = false
