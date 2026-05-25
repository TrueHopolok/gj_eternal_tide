class_name Enemy
extends CharacterBody2D


signal died(score: int)

const GROUP: StringName = &"Enemy"
const TARGET := Vector2.ZERO

@export var health: int = 1
@export var speed: float = 40.0
@export var score: int = 2
@export var damage: int = 1

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _hit_sfx_player: AudioStreamPlayer = get_tree().get_first_node_in_group('EnemySFX')


func _ready() -> void:
	_sprite.play()
	speed = clampf(randfn(speed, speed * 0.25), speed * 0.5, speed * 2)
	GameManager.get_instance().register_enemy(self)


func _physics_process(_delta: float) -> void:
	velocity = global_position.direction_to(TARGET) * speed
	move_and_slide()
	look_at(velocity)


func _die() -> void:
	queue_free()
	_hit_sfx_player.play()
	died.emit(score)


func target_reached() -> int:
	queue_free()
	died.emit(0)
	return damage


func take_damage() -> void:
	if health <= 0:
		return
	health -= 1
	if health <= 0:
		_die()
