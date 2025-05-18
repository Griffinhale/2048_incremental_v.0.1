extends Node
# In UpgradeManager.gd or external .tres/.json/.gd resource
var prestige_upgrades = {
	"start_tile_2": {
		"name": "Start with Tile 2",
		"description": "Begin each board with a tile value of 2.",
		"cost": 5,
		"effect": {
			"starting_tile": 2
		}
	},
	"spawn_bias": {
		"name": "Spawn Bias",
		"description": "Reduce chance of spawning 1s.",
		"cost": 10,
		"effect": {
			"spawn_bias": true
		}
	}
}
