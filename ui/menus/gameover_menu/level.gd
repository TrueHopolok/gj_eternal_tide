extends Label


func _ready() -> void:
	text = "Your level:        %d
Best level:         %d" % [Persistence.current_level, Persistence.best_level]
