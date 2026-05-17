extends Label


func _ready() -> void:
	text = str(Persistence.best_level + 1)
