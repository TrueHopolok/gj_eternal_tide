extends Button


func _ready() -> void:
	visible = OS.has_feature("mobile")


func _pressed() -> void:
	get_tree().paused = !get_tree().paused
