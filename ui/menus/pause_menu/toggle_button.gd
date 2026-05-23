extends Button


func _ready() -> void:
	visible = OS.has_feature("mobile") || OS.has_feature("web")


func _pressed() -> void:
	get_tree().paused = !get_tree().paused
