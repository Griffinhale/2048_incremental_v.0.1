var generators_v1 = [
  {
	"id": "gen_0",
	"label": "Basic Combiner",
	"tile_targets": [0, 1],
	"level": 1,
	"base_yield": 0.2,
	"growth_curve": "linear",
	"growth_factor": 1.0,
	"interval_seconds": 1.0,
	"multiplier": 1.0
  },
  {
	"id": "gen_1",
	"label": "Twin Amplifier",
	"tile_targets": [2, 3],
	"level": 1,
	"base_yield": 1.0,
	"growth_curve": "exponential",
	"growth_factor": 1.1,
	"interval_seconds": 2.0,
	"multiplier": 1.0
  },
  {
	"id": "gen_2",
	"label": "Prime Reactor",
	"tile_targets": [5, 7],
	"level": 1,
	"base_yield": 0.8,
	"growth_curve": "exponential",
	"growth_factor": 1.15,
	"interval_seconds": 3.0,
	"multiplier": 1.0
  },
  {
	"id": "gen_3",
	"label": "Echo Producer",
	"tile_targets": [9, 6],
	"level": 1,
	"base_yield": 1.5,
	"growth_curve": "linear",
	"growth_factor": 1.5,
	"interval_seconds": 4.0,
	"multiplier": 1.0
  },
  {
	"id": "gen_4",
	"label": "Recursive Synth",
	"tile_targets": [10, 4],
	"level": 1,
	"base_yield": 2.0,
	"growth_curve": "exponential",
	"growth_factor": 1.25,
	"interval_seconds": 6.0,
	"multiplier": 1.0
  },
  {
	"id": "gen_5",
	"label": "Singularity Driver",
	"tile_targets": [8, 11],
	"level": 1,
	"base_yield": 3.5,
	"growth_curve": "linear",
	"growth_factor": 2.0,
	"interval_seconds": 10.0,
	"multiplier": 1.0
  }
]
#
#gen_0 Basic	"Start game with its tiles pre-spawned on board"
#gen_1 Twin	"Doubles output if both tile types are present in queue"
#gen_2 Prime	"Prime bonus: output scales by prestige level"
#gen_3 Echo	"Output repeats for 3 ticks after a merge on tile 6/9"
#gen_4 Recursive	"Scales from number of unlocked upgrades"
#gen_5 Singularity	"Global bonus to all passive income every 100 seconds"
