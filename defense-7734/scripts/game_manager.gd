
extends Node

signal coins_changed(value: int)
signal lives_changed(value: int)
signal game_over

var coins: int = 150
var lives: int = 20
var game_finished: bool = false


func _ready() -> void:
	reset_game()


func reset_game() -> void:
	coins = 150
	lives = 20
	game_finished = false

	coins_changed.emit(coins)
	lives_changed.emit(lives)


func add_coins(amount: int) -> void:
	if game_finished:
		return

	coins += amount
	coins_changed.emit(coins)


func spend_coins(amount: int) -> bool:
	if game_finished or coins < amount:
		return false

	coins -= amount
	coins_changed.emit(coins)
	return true


func lose_life(amount: int = 1) -> void:
	if game_finished:
		return

	lives = max(0, lives - amount)
	lives_changed.emit(lives)

	if lives <= 0:
		game_finished = true
		game_over.emit()


func finish_game() -> void:
	if game_finished:
		return

	game_finished = true
	game_over.emit()
