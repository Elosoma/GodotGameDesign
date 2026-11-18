
extends Node2D

@export var attack_range: float = 180.0
@export var fire_rate: float = 1.0
@export var damage: float = 25.0

@export var projectile_scene: PackedScene

var cooldown: float = 0.0
var target: Node2D = null

func _ready() -> void:
	add_to_group("towers")

func _process(delta: float) -> void:
	cooldown -= delta

	find_target()

	if is_instance_valid(target):
		if cooldown <= 0.0:
			shoot()
			cooldown = 1.0 / fire_rate

	queue_redraw()


func find_target() -> void:
	target = null
	var closest_distance = attack_range

	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue

		var distance = global_position.distance_to(
			enemy.global_position
		)

		if distance < closest_distance:
			closest_distance = distance
			target = enemy


func shoot() -> void:
	if not is_instance_valid(target):
		return

	if projectile_scene == null:
		return

	var projectile = projectile_scene.instantiate()

	get_tree().current_scene.add_child(projectile)

	projectile.global_position = global_position
	projectile.setup(target, damage)


func _draw() -> void:
	# Representación del alcance de la torre.
	draw_arc(
		Vector2.ZERO,
		attack_range,
		0.0,
		TAU,
		64,
		Color(0.3, 0.7, 1.0, 0.3),
		1.5
	)

	# Cuerpo de la torre.
	draw_circle(Vector2.ZERO, 19.0, Color(0.2, 0.35, 0.85))
	draw_circle(Vector2.ZERO, 10.0, Color(0.5, 0.7, 1.0))
