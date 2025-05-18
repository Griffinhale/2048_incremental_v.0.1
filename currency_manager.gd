extends Node

signal currency_changed(new_value: float)

var currency: float = 0.0

func _ready():
	# You could load saved currency here in the future
	pass

func add_currency(amount: float) -> void:
	currency += amount
	emit_signal("currency_changed", currency)

func spend_currency(amount: float) -> bool:
	if currency >= amount:
		currency -= amount
		emit_signal("currency_changed", currency)
		return true
	return false

func get_currency() -> float:
	return currency
