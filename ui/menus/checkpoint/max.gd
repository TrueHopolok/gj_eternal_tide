extends BetterButton


func _on_press() -> void:
	var lvl: int = Persistence.best_level
	%Level.text = str(lvl)
	Persistence.current_level = lvl
