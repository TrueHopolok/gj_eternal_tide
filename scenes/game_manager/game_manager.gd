class_name GameManager
extends Node


@export var start_at_level: int = 0
@export var spawn_policy: SpawnPolicy
@export var cursor_manager: CursorManager
@export var castle: Castle
@export var tutorial: Tutorial

var _event_queue: Array[TimedEvent] = []
var _active_enemies: int = 0
var _level_counter: int = -1 # first level is 0 not 1

var _cursor_start: float
var _cursor_end: float
var _cursor_clicks: int
var _cursor_clicks_left: int

const GAME_OVER_SCENE: StringName = &"res://ui/menus/gameover_menu/gameover_menu.tscn"
const GROUP_NAME: StringName = &"GameManager"
const CURSOR_TIME: float = 0.5


static func get_instance() -> GameManager:
	var node := (Engine.get_main_loop() as SceneTree).get_first_node_in_group(GROUP_NAME) as GameManager
	if not is_instance_valid(node):
		push_error("[GameManager.get_instance]: no game manager instance found")
		return null
	return node


func _ready() -> void:
	if start_at_level != 0:
		_level_counter = start_at_level - 1
	else:
		_level_counter = Persistence.current_level - 2
	add_to_group(GROUP_NAME)

	Persistence.current_score = 0

	randomize()

	cursor_manager.clicked.connect(_on_click)

	if spawn_policy == null:
		push_error("[GameManager.ready]: no spawn policy")
		return

	if castle == null:
		push_error("[GameManager.ready]: no castle")
		return

	if cursor_manager == null:
		push_error("[GameManager.ready]: no cursor manager")
		return

	if tutorial == null:
		push_error("[GameManager.ready]: no tutorial")
		return

	spawn_policy.initialize()

	_next_level()

	castle.game_over.connect(_on_game_over)
	cursor_manager.set_radius(1)


func _physics_process(_delta: float) -> void:
	var now := Time.get_ticks_usec()

	while not _event_queue.is_empty() and _event_queue.back().t <= now:
		_process_event(_event_queue.pop_back())
		_try_finish_level()


func _clamp_remap(v: float, istart: float, istop: float, ostart: float, ostop: float) -> float:
	return remap(clampf(v, minf(istart, istop), maxf(istart, istop)), istart, istop, ostart, ostop)


func _process_event(ev: TimedEvent) -> void:
	#print("[GameManager.process_event]: %s" % ev)

	var m: EnemyMother = EnemyMother.get_instance()
	if ev.spawn != null:
		var inst: Node2D = ev.spawn.instantiate()
		_active_enemies += _get_enemy_amount(inst)
		m.single_spawn(inst)

	if not ev.tide.is_empty():
		var insts: Array[Node2D] = []

		for p: PackedScene in ev.tide:
			var inst: Node2D = p.instantiate()
			_active_enemies += _get_enemy_amount(inst)
			insts.push_back(inst)

		m.tide_spawn(insts)


func _on_enemy_death(enemy_score: int = 1) -> void:
	_active_enemies -= 1
	Persistence.current_score += enemy_score

	_try_finish_level()


func _try_finish_level() -> void:
	if _active_enemies > 0 or not _event_queue.is_empty():
		return

	# If the last enemy of the wave kills the castle, execution order of game_over signal and
	# next level is not obvious and may race.
	# Because of this, next level is called at the end of the frame.
	_next_level.call_deferred()


func _next_level() -> void:
	if castle.is_dead():
		# Do not advance to next level if the last enemy killed us.
		# Normally this will softlock the game, but since we are dead,
		# we will be moved to game over scene shortly.
		return

	_level_counter += 1
	Persistence.current_level = _level_counter + 1
	Persistence.submit()

	tutorial.on_level_switched(_level_counter + 1)
	castle.print_level(_level_counter + 1)
	print("Starting level %d" % _level_counter)

	var spec := spawn_policy.sample(_level_counter)

	print("Generated spec: enemies=%d @ %fHz tides=%d @ %fHz" % [
		spec.enemies.size(), 1/spec.enemy_spawn_interval, spec.tides.size(), 1/spec.tide_spawn_interval])

	_execute_level_spec(spec)


func _execute_level_spec(spec: SpawnPolicy.Sample) -> void:
	var start := Time.get_ticks_usec() + 1000000 # in 1 sec

	for i: int in spec.enemies.size():
		var delay: int = roundi(spec.enemy_spawn_interval * 1e6) * (i + 1)
		_event_queue.push_back(TimedEvent.single(start+delay, spec.enemies[i]))

	for i: int in spec.tides.size():
		var delay: int = roundi(spec.tide_spawn_interval * 1e6) * (i + 1)
		_event_queue.push_back(TimedEvent.many(start+delay, spec.tides[i]))

	_event_queue.sort_custom(func (lhs: TimedEvent, rhs: TimedEvent) -> bool:
		return lhs.t > rhs.t)

	_cursor_start = spec.cursor_start
	_cursor_end = spec.cursor_end
	_cursor_clicks = spec.cursor_clicks
	_cursor_clicks_left = spec.cursor_clicks

	cursor_manager.tween_radius(spec.cursor_start)


func _on_click() -> void:
	_cursor_clicks_left -= 1
	_cursor_clicks_left = maxi(_cursor_clicks_left, 0)
	cursor_manager.tween_radius(_clamp_remap(_cursor_clicks_left, _cursor_clicks, 0, _cursor_start, _cursor_end))


func _on_game_over() -> void:
	Persistence.submit()
	await get_tree().create_timer(1.5).timeout
	Transition.change_scene_path(GAME_OVER_SCENE)


func _get_enemy_amount(node: Node) -> int:
	if node.has_method("get_enemy_amount"):
		return node.get_enemy_amount()
	else:
		return 1


func register_enemy(enemy: Enemy) -> void:
	enemy.died.connect(_on_enemy_death, CONNECT_ONE_SHOT)


class LevelSpec:
	var enemies: Array[EnemySpec] = []
	var tides: Array[Array] = [] # Array[Array[EnemySpec]]


class TimedEvent:
	var t: int
	var spawn: PackedScene
	var tide: Array[PackedScene]

	static func single(time: int, v: PackedScene) -> TimedEvent:
		var te := TimedEvent.new()
		te.t = time
		te.spawn = v
		return te

	static func many(time: int, v: Array[PackedScene]) -> TimedEvent:
		var te := TimedEvent.new()
		te.t = time
		te.tide =  v
		return te


	func _to_string() -> String:
		var dur := t - Time.get_ticks_usec()
		return "TimedEvent(single=%s, tide=%s, in=%ss)" % [spawn != null, tide.size(), dur * 0.000001]
