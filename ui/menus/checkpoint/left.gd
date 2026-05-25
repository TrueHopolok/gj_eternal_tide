extends BetterButton


func _on_press() -> void:
	var lvl: int = maxi(int(%Level.text) - 1, 1)
	%Level.text = str(lvl)
	Persistence.current_level = lvl
