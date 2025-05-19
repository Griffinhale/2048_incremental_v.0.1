extends Node
# In UpgradeManager.gd or external .tres/.json/.gd resource
var upgrades: Dictionary = {
	"generators": [
		{ "id": "gen_yield_mult_1", "cost": 100, "tier": 1, "effect": { "generator_yield_mult": 1.1 }, "scaling": { "type": "soft_cap", "cap": 3.0, "curve": "log" }},
		{ "id": "gen_yield_mult_2", "cost": 250, "tier": 1, "effect": { "generator_yield_mult": 1.25 }},
		{ "id": "gen_interval_reduce", "cost": 300, "tier": 1, "effect": { "generator_interval_mult": 0.9 }},
		{ "id": "gen_synergy_bonus", "cost": 500, "tier": 2, "effect": { "generator_cross_synergy": 0.05 }},
		{ "id": "gen_tile_value_scaling", "cost": 400, "tier": 2, "effect": { "tile_value_bonus_per_level": 0.05 }},
		{ "id": "gen_idle_tick_yield_boost", "cost": 350, "tier": 2, "effect": { "generator_idle_yield_mult": 1.1 }},
		{ "id": "gen_dual_target_expansion", "cost": 600, "tier": 3, "effect": { "generator_tile_target_count": 3 }, "keystone": true }
	],

	"conversion": [
		{ "id": "conversion_formula_add", "cost": 0, "tier": 1, "effect": { "score_formula": "score + moves" }},
		{ "id": "conversion_formula_mult", "cost": 300, "tier": 1, "effect": { "score_formula": "score * moves" }},
		{ "id": "conversion_formula_log_root", "cost": 450, "tier": 2, "effect": { "score_formula": "log(score+1)*sqrt(moves)" }},
		{ "id": "conversion_bonus_scaling", "cost": 500, "tier": 2, "effect": { "score_to_currency_multiplier": 1.2 }, "scaling": { "type": "linear_decay", "decay": 0.05 }},
		{ "id": "conversion_generator_tile_boost", "cost": 350, "tier": 2, "effect": { "tile_currency_yield_from_gen_level": 1.0 }},
		{ "id": "conversion_efficiency_curve_soften", "cost": 600, "tier": 3, "effect": { "conversion_soft_cap_threshold_add": 25 }, "keystone": true }
	],

	"active": [
		{ "id": "move_currency_gain_add", "cost": 100, "tier": 1, "effect": { "currency_per_move_add": 0.05 }},
		{ "id": "merge_yield_mult", "cost": 200, "tier": 1, "effect": { "currency_per_merge_mult": 1.15 }},
		{ "id": "combo_move_bonus", "cost": 300, "tier": 2, "effect": { "combo_move_bonus_mult": 1.5 }},
		{ "id": "spawn_tile_boost_on_click", "cost": 400, "tier": 2, "effect": { "tile_spawn_multiplier": 1.25 }},
		{ "id": "tile_spawn_from_generator_strength", "cost": 500, "tier": 2, "effect": { "spawn_tile_value_bonus_per_gen_level": 0.5 }},
		{ "id": "click_to_generate_tick", "cost": 600, "tier": 3, "effect": { "manual_generator_tick_on_click": true }, "keystone": true }
	],

	"discipline": [
		{ "id": "low_move_bonus", "cost": 200, "tier": 1, "effect": { "bonus_if_moves_below": [30, 1.2] }},
		{ "id": "prime_tile_only_mode", "cost": 300, "tier": 1, "effect": { "only_prime_tiles_yield": true }},
		{ "id": "score_decay_resistance", "cost": 350, "tier": 2, "effect": { "score_decay_resist_percent": 0.2 }},
		{ "id": "symmetry_bonus", "cost": 400, "tier": 2, "effect": { "bonus_if_symmetric_board": 1.25 }},
		{ "id": "precision_score_target_bonus", "cost": 300, "tier": 2, "effect": { "bonus_if_score_mod_equals": [5, 0] }},
		{ "id": "single_generator_bonus", "cost": 500, "tier": 3, "effect": { "bonus_if_one_generator_used": 1.5 }, "keystone": true }
	],

	"reset": [
		{ "id": "prestige_start_currency_add", "cost": 250, "tier": 1, "effect": { "currency_on_reset_add": 50 }},
		{ "id": "prestige_currency_mult_per_cycle", "cost": 400, "tier": 2, "effect": { "prestige_cycle_currency_mult_add": 0.1 }},
		{ "id": "prestige_click_scaling", "cost": 500, "tier": 2, "effect": { "click_currency_gain_per_prestige": 0.01 }},
		{ "id": "prestige_generator_autobuy", "cost": 600, "tier": 2, "effect": { "generator_autobuy_on_reset": true }},
		{ "id": "prestige_inheritance_system", "cost": 700, "tier": 3, "effect": { "retain_generator_levels": 1 }, "keystone": true },
		{ "id": "prestige_unlock_next_tileset", "cost": 500, "tier": 3, "effect": { "unlock_next_tileset_on_prestige": true }, "keystone": true }
	],

	"lore": [
		{ "id": "queue_visible_length_add", "cost": 100, "tier": 1, "effect": { "queue_visible_count_add": 1 }},
		{ "id": "tile_highlight_logic_enabled", "cost": 250, "tier": 1, "effect": { "tile_behavior_overlay": true }},
		{ "id": "upgrade_panel_tooltips_on", "cost": 0, "tier": 1, "effect": { "tooltips_enabled": true }},
		{ "id": "offline_earnings_enable", "cost": 450, "tier": 2, "effect": { "offline_earnings_enabled": true }},
		{ "id": "codex_unlock_math_1", "cost": 100, "tier": 2, "effect": { "unlock_codex_entry": "math_intro" }},
		{ "id": "generator_unlock_new_type", "cost": 300, "tier": 3, "effect": { "unlock_generator_type": "gen_6" }, "keystone": true }
	]
}
