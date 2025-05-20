extends Control

var next_value: int = 0

func set_value(value: int):
	next_value = value
	queue_redraw()
