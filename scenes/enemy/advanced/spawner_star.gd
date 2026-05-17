extends Node2D


const STAR_CHILD := preload("res://scenes/enemy/advanced/star.tscn")
const StarChild := preload("res://scenes/enemy/advanced/star.gd")

const STAR_SPIT := preload("res://scenes/enemy/advanced/star_spit.tscn")

const STAR_SPAWN_DIST: float = 110.0
const TIME: float = 5.0
const DAMAGE: int = 5

var _click_n: int = 0
var _last_click: int = -1
var _direction: int = 0 # 0 if undecided, -1 or 1
var _children: Array[StarChild]

@onready var _sound_punish := get_tree().get_first_node_in_group("ImpossibleSFX") as AudioStreamPlayer
@onready var _sound_ok := get_tree().get_first_node_in_group("StarOkSFX") as AudioStreamPlayer


func _ready() -> void:
	var initial_pos := Vector2.from_angle(randf_range(0, TAU)) * STAR_SPAWN_DIST

	for i: int in 5:
		var inst := STAR_CHILD.instantiate() as StarChild
		inst.global_position = initial_pos.rotated(TAU / 5 * 2 * i)
		inst.clicked.connect(_child_clicked.bind(i))
		_children.push_back(inst)
		get_parent().add_child(inst)
		inst.mark_target()

	_children[0].damage = DAMAGE

	get_tree().create_timer(TIME).timeout.connect(func () -> void:
		for child: StarChild in _children:
			child.start_running()
	)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	for i: int in 5:
		var from := _child_at(i)
		var to := _child_at(i+1)
		if not is_instance_valid(from) or not is_instance_valid(to):
			continue
		draw_line(to_local(from.global_position), to_local(to.global_position), Color.hex(0xf7cbe9ff), 1.0)


func _child_clicked(idx: int) -> void:
	if idx == _last_click:
		_reset()
		return

	if _click_n == 0:
		for i: int in 5:
			_child_at(i).reset()
		_child_at(idx).mark_clicked()
		_child_at(idx+1).mark_target()
		_spit(_child_at(idx), _child_at(idx+1))
		_child_at(idx-1).mark_target()
		_spit(_child_at(idx), _child_at(idx-1))
		_sound_ok.play()
	elif _click_n == 1:
		if idx != _wrap(_last_click + 1) and idx != _wrap(_last_click - 1):
			_reset()
			return
		_direction = 1 if idx == _wrap(_last_click + 1) else -1
		_child_at(_last_click - _direction).reset()
		_child_at(idx).mark_clicked()
		_child_at(idx + _direction).mark_target()
		_spit(_child_at(idx), _child_at(idx+_direction))

		_sound_ok.play()
	else:
		if idx != _wrap(_last_click + _direction):
			_reset()
			return
		_child_at(idx).mark_clicked()
		_child_at(idx + _direction).mark_target()
		_spit(_child_at(idx), _child_at(idx+_direction))
		_sound_ok.play()

	_click_n += 1
	_last_click = idx

	if _click_n == 5:
		for child: StarChild in _children:
			child.die()

		queue_free()


func _spit(from: Node2D, to: Node2D):
	var inst := STAR_SPIT.instantiate()
	add_child(inst)
	inst.global_position = from.global_position
	inst.target = to


func _reset() -> void:
	# update: don't punish, just sound
	_sound_punish.play()


func _wrap(idx: int) -> int:
	return wrapi(idx, 0, _children.size())


func _child_at(idx: int) -> StarChild:
	return _children[_wrap(idx)]


func get_enemy_amount() -> int:
	return 5
