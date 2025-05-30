# Autoload as PrestigeManager.gd
extends Node


var prestige_currency: float = 0.0
var upgrades_owned := {}
var base_starting_tile: int = 1

func can_afford(upgrade_id: String) -> bool:
	var upgrade = UpgradeManager.get_upgrade("prestige", upgrade_id)
	return prestige_currency >= upgrade.cost

func buy_upgrade(upgrade_id: String) -> bool:
	var upgrade = UpgradeManager.get_upgrade("prestige", upgrade_id)
	if can_afford(upgrade_id):
		prestige_currency -= upgrade.cost
		upgrades_owned[upgrade_id] = true
		perform_prestige_reset()
		return true
	return false

func perform_prestige_reset():
	StatsTracker.clear_stashed_games()
	CurrencyManager.reset()
	GeneratorManager.reset_all()
#	ScreenManager.reset_board()
	# Other hooks...
func get_current_prestige_bonuses() -> Dictionary:
	# Stub - return empty for now
	# In v0.5+ this will return actual prestige bonuses
	return {}
