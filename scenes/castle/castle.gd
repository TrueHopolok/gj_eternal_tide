class_name Castle
extends Area2D


signal game_over

const GROUP: StringName = &"Castle"

# NOTE: can be used for overheal mechanics
@export var max_health: int = 10
@export var health: int = 10

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _label: Label = $LevelLabel
@onready var _death_audio_player: AudioStreamPlayer = $CastleDeathSFX
@onready var _damage_audio_player: AudioStreamPlayer = $CastleDamageSFX
@onready var _heal_audio_player: AudioStreamPlayer = $CastleHealSFX
@onready var flower_path: Node = $FlowerPath


static func get_instance() -> Castle:
	return Engine.get_main_loop().get_first_node_in_group(GROUP)


func _ready() -> void:
	_sprite.play(&"idle")
	body_entered.connect(_get_kicked)
	_sprite.animation_finished.connect(_on_animation_finished)
	remove_child(_label)
	_update_health_visual()


func _on_animation_finished() -> void:
	if _sprite.animation == &"hit":
		if health <= 0:
			_sprite.play(&"dead")
		else:
			_sprite.play(&"idle")


func _get_kicked(body: Node2D) -> void:
	if body.has_method(&"target_reached"):
		var dmg: int = body.target_reached()
		take_damage(dmg)
	else:
		push_error("Castle: took damage from %s, which has no target_reached()." % body.name)
		body.queue_free()


func take_damage(dmg: int) -> void:
	if health <= 0:
		return
	health = clampi(health - dmg, 0, max_health)
	_update_health_visual()
	if dmg > 0:
		_sprite.play(&"hit")
		if health <= 0:
			_death_audio_player.play()
			game_over.emit()
		else:
			_damage_audio_player.play()
	else:
		_heal_audio_player.play()


func print_level(level: int) -> void:
	if not is_node_ready():
		await ready

	var l := _label.duplicate()
	l.show()
	l.text = "Level %d" % level
	add_child(l)
	var t := l.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(l, "position:y", -50, 3.0).as_relative()
	t.parallel().tween_property(l, "modulate:a", 0.0, 3.0).set_ease(Tween.EASE_IN_OUT)
	t.chain().tween_callback(l.queue_free)


func is_dead() -> bool:
	return health <= 0


func _update_health_visual() -> void:
	for i: int in health:
		flower_path.get_child(i).show()

	for i: int in range(health, flower_path.get_child_count()):
		flower_path.get_child(i).hide()
