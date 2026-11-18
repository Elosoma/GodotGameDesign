
extends Node2D

signal died(reward: int)
signal reached_base

@export var max_health: float = 100.0
@export var speed: float = 85.0
@export var reward: int = 10
@export var base_damage: int = 1

var health: float
var path_points: PackedVector2Array = []
var current_point: int = 0
var finished: bool = false


func _ready() -> void:
	health = max_health
	add_to_group("enemies")
	queue_redraw()


func set_path(points: PackedVector2Array) -> void:
	path_points = points
	current_point = 0

	if path_points.size() > 0:
		global_position = path_points[0]


func _process(delta: float) -> void:
	if finished or path_points.is_empty():
		return

	if current_point >= path_points.size():
		return

	var target = path_points[current_point]
	var direction = global_position.direction_to(target)

	global_position = global_position.move_toward(
		target,
		speed * delta
	)

	if global_position.distance_to(target) < 2.0:
		current_point += 1

		if current_point >= path_points.size():
			finished = true
			reached_base.emit()
			queue_free()


func take_damage(amount: float) -> void:
	if finished:
		return

	health -= amount
	queue_redraw()

	if health <= 0:
		finished = true
		died.emit(reward)
		queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 15.0, Color(0.85, 0.18, 0.18))
	draw_circle(Vector2(-5, -3), 3.0, Color.WHITE)
	draw_circle(Vector2(5, -3), 3.0, Color.WHITE)

	var bar_width = 35.0
	var health_ratio = clampf(health / max_health, 0.0, 1.0)

	draw_rect(
		Rect2(Vector2(-bar_width / 2, -25), Vector2(bar_width, 5)),
		Color.DARK_RED
	)

	draw_rect(
		Rect2(Vector2(-bar_width / 2, -25),
		Vector2(bar_width * health_ratio, 5)),
		Color.GREEN
	)
