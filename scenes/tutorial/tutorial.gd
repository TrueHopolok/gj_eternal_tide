class_name Tutorial
extends CanvasLayer


@export var hints: Dictionary[int, String]

@onready var _label: RichTextLabel = $Hint


func on_level_switched(level_num: int) -> void:
	if level_num in hints.keys():
		_show_hint(hints[level_num])


func _show_hint(hint: String) -> void:
	if not is_node_ready():
		await ready

	var l := _label.duplicate()
	l.show()
	l.text = hint
	add_child(l)
	var t := l.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(l, "position:y", -20, 3.0).as_relative()
	t.parallel().tween_property(l, "modulate:a", 0.0, 10.0).set_ease(Tween.EASE_IN_OUT)
	t.chain().tween_callback(l.queue_free)
