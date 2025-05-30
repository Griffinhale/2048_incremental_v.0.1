# res://data/generator_collection.gd
class_name GeneratorCollection
extends Resource

@export var generators: Array = []

func get_generator_by_id(id: String) -> GeneratorData:
	for gen in generators:
		if gen.id == id:
			return gen
	return null

func get_active_generators() -> Array[GeneratorData]:
	return generators.filter(func(gen): return gen.active and gen.level > 0)
