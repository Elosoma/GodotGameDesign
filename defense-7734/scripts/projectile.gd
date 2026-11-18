
extends Node2D

@export var speed: float = 350.0
@export var damage: float = 25.0

var target: Node2D = null


func setup(enemy: Node2D, projectile_damage: float) -> void:
	target = enemy
	damage = projectile_damage


func _process(delta: float) -> void:
	if not is_instance_valid(target):
		queue_free()
		return

	var distance = global_position.distance_to(target.global_position)

	if distance < 12.0:
		if target.has_method("take_damage"):
			target.take_damage(damage)

		queue_free()
		return

	global_position = global_position.move_toward(
		target.global_position,
		speed * delta
	)

	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 5.0, Color.YELLOW)
