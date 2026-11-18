extends Node2D

@export var enemy_scene: PackedScene
@export var tower_scene: PackedScene

const TOWER_COST: int = 100
const MAX_WAVES: int = 10

var path_points := PackedVector2Array([
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
var wave_in_progress: bool = false

var hud: CanvasLayer
var info_label: Label
var coins_label: Label
var lives_label: Label
var wave_label: Label
var message_label: Label
var build_button: Button
var next_wave_button: Button


func _ready() -> void:
	GameManager.reset_game()
	create_hud()

	GameManager.coins_changed.connect(update_coins)
	GameManager.lives_changed.connect(update_lives)
	GameManager.game_over.connect(on_game_over)

	update_coins(GameManager.coins)
	update_lives(GameManager.lives)
	queue_redraw()


func _process(delta: float) -> void:
	if not game_running:
		return

	if enemies_to_spawn > 0:
		spawn_timer -= delta
		if spawn_timer <= 0.0:
			spawn_enemy()
			enemies_to_spawn -= 1
			spawn_timer = spawn_delay

	if wave_in_progress:
		var remaining_enemies := get_tree().get_nodes_in_group("enemies")
		if enemies_to_spawn == 0 and remaining_enemies.is_empty():
			wave_in_progress = false
			next_wave_button.disabled = false

			if wave >= MAX_WAVES:
				show_victory()
			else:
				info_label.text = "Oleada completada. ¡Prepárate para la siguiente!"


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if build_mode and game_running:
				place_tower(get_global_mouse_position())

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			get_tree().reload_current_scene()
		elif event.keycode == KEY_ESCAPE and build_mode:
			toggle_build_mode()


func _draw() -> void:
	draw_rect(
		Rect2(Vector2.ZERO, Vector2(1280, 720)),
		Color(0.22, 0.48, 0.25)
	)

	for i in range(path_points.size() - 1):
		draw_line(
			path_points[i],
			path_points[i + 1],
			Color(0.55, 0.43, 0.30),
			65.0,
			true
		)
		draw_line(
			path_points[i],
			path_points[i + 1],
			Color(0.72, 0.60, 0.43),
			4.0,
			true
		)


func create_hud() -> void:
	hud = CanvasLayer.new()
	hud.name = "HUD"
	hud.layer = 10
	add_child(hud)

	var panel := PanelContainer.new()
	panel.name = "StatusPanel"
	panel.position = Vector2(16, 16)
	hud.add_child(panel)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 8)
	panel.add_child(layout)

	var title := Label.new()
	title.text = "DEFENSA 7734"
	title.add_theme_font_size_override("font_size", 20)
	layout.add_child(title)

	coins_label = Label.new()
	layout.add_child(coins_label)

	lives_label = Label.new()
	layout.add_child(lives_label)

	wave_label = Label.new()
	wave_label.text = "Oleada: 0 / " + str(MAX_WAVES)
	layout.add_child(wave_label)

	build_button = Button.new()
	build_button.text = "Construir torre (%d)" % TOWER_COST
	build_button.custom_minimum_size = Vector2(230, 38)
	build_button.pressed.connect(toggle_build_mode)
	layout.add_child(build_button)

	next_wave_button = Button.new()
	next_wave_button.text = "Iniciar oleada"
	next_wave_button.custom_minimum_size = Vector2(230, 38)
	next_wave_button.pressed.connect(start_wave)
	layout.add_child(next_wave_button)

	info_label = Label.new()
	info_label.text = "Defiende tu base. Construye torres y comienza una oleada."
	info_label.position = Vector2(16, 190)
	info_label.add_theme_color_override("font_color", Color.WHITE)
	hud.add_child(info_label)

	message_label = Label.new()
	message_label.position = Vector2(400, 300)
	message_label.add_theme_font_size_override("font_size", 30)
	message_label.add_theme_color_override("font_color", Color.WHITE)
	hud.add_child(message_label)


func update_coins(value: int) -> void:
	if is_instance_valid(coins_label):
		coins_label.text = "Monedas: " + str(value)


func update_lives(value: int) -> void:
	if is_instance_valid(lives_label):
		lives_label.text = "Vidas: " + str(value)


func toggle_build_mode() -> void:
	if not game_running:
		return

	build_mode = not build_mode
	if build_mode:
		info_label.text = "Modo construcción: haz clic en una zona libre. (Esc para cancelar)"
	else:
		info_label.text = "Construcción cancelada."


func start_wave() -> void:
	if not game_running or wave_in_progress:
		return

	if wave >= MAX_WAVES:
		return

	if enemy_scene == null:
		info_label.text = "ERROR: asigna Enemy.tscn en Main.tscn."
		return

	if not get_tree().get_nodes_in_group("enemies").is_empty():
		info_label.text = "Espera a que termine la oleada actual."
		return

	wave += 1
	wave_in_progress = true
	enemies_to_spawn = 5 + wave * 2
	spawn_delay = maxf(0.35, 1.0 - wave * 0.04)
	spawn_timer = 0.0

	wave_label.text = "Oleada: %d / %d" % [wave, MAX_WAVES]
	next_wave_button.disabled = true
	info_label.text = "¡Oleada %d en marcha!" % wave


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


func place_tower(tower_position: Vector2) -> void:
	if not build_mode or not game_running:
		return

	if not is_valid_tower_position(tower_position):
		info_label.text = "No puedes construir ahí: elige una zona libre."
		return

	if tower_scene == null:
		info_label.text = "ERROR: asigna Tower.tscn en Main.tscn."
		return

	if not GameManager.spend_coins(TOWER_COST):
		info_label.text = "No tienes monedas suficientes."
		return

	var tower = tower_scene.instantiate()
	add_child(tower)
	tower.global_position = tower_position

	build_mode = false
	info_label.text = "¡Torre construida!"


func is_valid_tower_position(tower_position: Vector2) -> bool:
	if tower_position.x < 25.0 or tower_position.x > 1255.0:
		return false
	if tower_position.y < 25.0 or tower_position.y > 695.0:
		return false

	for i in range(path_points.size() - 1):
		var closest_point := Geometry2D.get_closest_point_to_segment(
			tower_position,
			path_points[i],
			path_points[i + 1]
		)
		if closest_point.distance_to(tower_position) < 55.0:
			return false

	for tower in get_tree().get_nodes_in_group("towers"):
		if is_instance_valid(tower):
			if tower.global_position.distance_to(tower_position) < 55.0:
				return false

	return true


func show_victory() -> void:
	game_running = false
	message_label.text = "¡VICTORIA!"
	info_label.text = "Has superado las %d oleadas. Pulsa R para volver a jugar." % MAX_WAVES


func on_game_over() -> void:
	game_running = false
	build_mode = false
	message_label.text = "¡DERROTA!"
	info_label.text = "Te has quedado sin vidas. Pulsa R para volver a jugar."
