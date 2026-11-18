
extends Node2D

@export var enemy_scene: PackedScene
@export var tower_scene: PackedScene

var path_points = PackedVector2Array([
	Vector2(-20, 180),
	Vector2(250, 180),
	Vector2(250, 420),
	Vector2(520, 420),
	Vector2(520, 160),
	Vector2(850, 160),
	Vector2(850, 520),
	Vector2(1300, 520)
])

var wave: int = 0
var enemies_to_spawn: int = 0
var spawn_timer: float = 0.0
var spawn_delay: float = 1.0

var build_mode: bool = false
var game_running: bool = true

var hud: CanvasLayer
var info_label: Label
var coins_label: Label
var lives_label: Label
var wave_label: Label
var message_label: Label
var build_button: Button
var next_wave_button: Button

var max_waves: int = 10
var wave_in_progress: bool = false


func _ready() -> void:
	GameManager.reset_game()

	create_hud()

	GameManager.coins_changed.connect(update_coins)
	GameManager.lives_changed.connect(update_lives)
	GameManager.game_over.connect(on_game_over)

	update_coins(GameManager.coins)
	update_lives(GameManager.lives)

	queue_redraw()

func show_victory() -> void:
	game_running = false
	message_label.text = "¡VICTORIA! Has defendido tu base."
	info_label.text = "Has superado las 10 oleadas."

func _process(delta: float) -> void:
	if not game_running:
		return

	if enemies_to_spawn > 0:
		spawn_timer -= delta

		if spawn_timer <= 0:
			spawn_enemy()
			enemies_to_spawn -= 1
			spawn_timer = spawn_delay
	
	if wave_in_progress:
		var remaining = get_tree().get_nodes_in_group("enemies")

		if enemies_to_spawn == 0 and remaining.is_empty():
			wave_in_progress = false

			if wave >= max_waves:
				show_victory()
			else:
				info_label.text = "Oleada completada. ¡Prepárate!"

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if build_mode and game_running:
				place_tower(get_global_mouse_position())

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R:
			get_tree().reload_current_scene()

func _draw() -> void:
	# Fondo verde.
	draw_rect(
		Rect2(Vector2.ZERO, Vector2(1280, 720)),
		Color(0.22, 0.48, 0.25)
	)

	# Camino.
	for i in range(path_points.size() - 1):
		draw_line(
			path_points[i],
			path_points[i + 1],
			Color(0.55, 0.43, 0.30),
			65.0,
			true
		)

	# Bordes del camino.
	for i in range(path_points.size() - 1):
		draw_line(
			path_points[i],
			path_points[i + 1],
			Color(0.72, 0.60, 0.43),
			4.0,
			true
		)


func create_hud() -> void:
	hud = CanvasLayer.new()
	add_child(hud)

	var panel = PanelContainer.new()
	panel.position = Vector2(10, 10)
	hud.add_child(panel)

	var layout = VBoxContainer.new()
	panel.add_child(layout)

	coins_label = Label.new()
	layout.add_child(coins_label)

	lives_label = Label.new()
	layout.add_child(lives_label)

	wave_label = Label.new()
	wave_label.text = "Oleada: 0"
	layout.add_child(wave_label)

	build_button = Button.new()
	build_button.text = "Construir torre (100 monedas)"
	build_button.pressed.connect(toggle_build_mode)
	layout.add_child(build_button)

	next_wave_button = Button.new()
	next_wave_button.text = "Iniciar siguiente oleada"
	next_wave_button.pressed.connect(start_wave)
	layout.add_child(next_wave_button)

	info_label = Label.new()
	info_label.text = "Defiende tu base."
	info_label.position = Vector2(10, 160)
	hud.add_child(info_label)

	message_label = Label.new()
	message_label.position = Vector2(500, 320)
	hud.add_child(message_label)


func update_coins(value: int) -> void:
	if is_instance_valid(coins_label):
		coins_label.text = "Monedas: " + str(value)


func update_lives(value: int) -> void:
	if is_instance_valid(lives_label):
		lives_label.text = "Vidas: " + str(value)


func toggle_build_mode() -> void:
	build_mode = not build_mode

	if build_mode:
		info_label.text = "Selecciona una zona libre para colocar la torre."
	else:
		info_label.text = "Construcción cancelada."


func start_wave() -> void:
	if wave >= max_waves:
		return

	wave_in_progress = true
	
	if enemies_to_spawn > 0 or get_tree().get_nodes_in_group("enemies").size() > 0:
		info_label.text = "Termina la oleada actual primero."
		return

	wave += 1
	enemies_to_spawn = 5 + wave * 2
	spawn_delay = maxf(0.35, 1.0 - wave * 0.04)
	spawn_timer = 0.0

	wave_label.text = "Oleada: " + str(wave)
	info_label.text = "¡Oleada " + str(wave) + " en marcha!"


func spawn_enemy() -> void:
	if enemy_scene == null:
		return

	var enemy = enemy_scene.instantiate()
	add_child(enemy)

	enemy.set_path(path_points)

	enemy.died.connect(on_enemy_died)
	enemy.reached_base.connect(on_enemy_reached_base)


func on_enemy_died(reward: int) -> void:
	GameManager.add_coins(reward)


func on_enemy_reached_base() -> void:
	GameManager.lose_life()


func place_tower(position: Vector2) -> void:
	if not build_mode:
		return

	if not is_valid_tower_position(position):
		info_label.text = "No puedes construir sobre el camino."
		return

	if not GameManager.spend_coins(100):
		info_label.text = "No tienes suficientes monedas."
		return

	if tower_scene == null:
		GameManager.add_coins(100)
		return

	var tower = tower_scene.instantiate()
	add_child(tower)
	tower.global_position = position

	build_mode = false
	info_label.text = "¡Torre construida!"


func is_valid_tower_position(position: Vector2) -> bool:
	if position.x < 20 or position.x > 1260:
		return false

	if position.y < 20 or position.y > 700:
		return false

	# Impide construir demasiado cerca del camino.
	for i in range(path_points.size() - 1):
		var distance = Geometry2D.get_closest_point_to_segment(
			position,
			path_points[i],
			path_points[i + 1]
		).distance_to(position)

		if distance < 55:
			return false

	# Impide superponer torres.
	for tower in get_tree().get_nodes_in_group("towers"):
		if tower.global_position.distance_to(position) < 55:
			return false

	return true


func on_game_over() -> void:
	game_running = false
	message_label.text = "¡DERROTA! Se ha perdido la partida."
	info_label.text = "Pulsa F6 para volver a probar."
