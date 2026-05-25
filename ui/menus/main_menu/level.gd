extends Label


func _ready() -> void:
	text = "Best level: %d" % Persistence.best_level
