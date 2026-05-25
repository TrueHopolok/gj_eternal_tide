extends BetterButton


func _on_press() -> void:
	var lvl: int = 1
	%Level.text = str(lvl)
	Persistence.current_level = lvl
