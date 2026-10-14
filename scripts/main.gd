extends Node2D

const PLAYER_SCENE = preload("res://scenes/player.tscn")
const ENEMY_SCENE = preload("res://scenes/enemy.tscn")
const BULLET_SCENE = preload("res://scenes/bullet.tscn")
const PICKUP_SCENE = preload("res://scenes/pickup.tscn")

@onready var entities: Node2D = $Entities
@onready var ui = $UI

var player = null
var score := 0
var lives := 3
var wave := 1
var kills := 0
var spawn_timer := 0.0
var game_active := false
var paused := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	randomize()
	ui.start_requested.connect(start_game)
	ui.resume_requested.connect(resume_game)
	ui.show_menu()

func start_game() -> void:
	get_tree().paused = false
	paused = false
	game_active = true
	for child in entities.get_children():
		child.queue_free()
	score = 0
	lives = 3
	wave = 1
	kills = 0
	spawn_timer = 0.6
	player = PLAYER_SCENE.instantiate()
	player.position = Vector2(240, 615)
	entities.add_child(player)
	player.shoot_requested.connect(_on_player_shoot)
	player.damaged.connect(_on_player_damaged)
	ui.update_stats(score, lives, wave)
	ui.update_boost(0.0, 0.0)
	ui.hide_overlay()

func _process(delta: float) -> void:
	if not game_active or paused:
		return
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		_spawn_enemy()
		spawn_timer = maxf(0.36, 1.30 - float(wave - 1) * 0.10)
	if is_instance_valid(player):
		ui.update_boost(player.rapid_remaining, player.double_remaining)

func _spawn_enemy() -> void:
	var enemy = ENEMY_SCENE.instantiate()
	var kind := randi_range(0, 2)
	enemy.configure(kind, wave)
	enemy.position = Vector2(randf_range(40.0, 440.0), -35.0)
	entities.add_child(enemy)
	enemy.destroyed.connect(_on_enemy_destroyed)
	enemy.shoot_requested.connect(_on_enemy_shoot)

func _on_player_shoot(origin: Vector2, double_shot: bool) -> void:
	if double_shot:
		_spawn_bullet(origin + Vector2(-12, 0), true)
		_spawn_bullet(origin + Vector2(12, 0), true)
	else:
		_spawn_bullet(origin, true)

func _on_enemy_shoot(origin: Vector2) -> void:
	if game_active and not paused:
		_spawn_bullet(origin, false)

func _spawn_bullet(origin: Vector2, is_player_bullet: bool) -> void:
	var bullet = BULLET_SCENE.instantiate()
	bullet.configure(is_player_bullet)
	bullet.position = origin
	entities.add_child.call_deferred(bullet)

func _on_enemy_destroyed(points: int, drop_position: Vector2) -> void:
	if not game_active:
		return
	score += points
	kills += 1
	if kills % 7 == 0:
		_spawn_pickup(drop_position)
	var next_wave := 1 + int(kills / 12)
	if next_wave != wave:
		wave = next_wave
	ui.update_stats(score, lives, wave)

func _spawn_pickup(drop_position: Vector2) -> void:
	var pickup = PICKUP_SCENE.instantiate()
	pickup.boost_kind = int(kills / 7) % 2
	pickup.position = drop_position
	entities.add_child.call_deferred(pickup)

func _on_player_damaged() -> void:
	lives -= 1
	ui.update_stats(score, lives, wave)
	if lives <= 0:
		_end_game()

func _end_game() -> void:
	game_active = false
	get_tree().paused = true
	ui.show_game_over(score)

func resume_game() -> void:
	paused = false
	get_tree().paused = false
	ui.hide_overlay()

func _unhandled_key_input(event: InputEvent) -> void:
	if not game_active:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_P:
			paused = not paused
			get_tree().paused = paused
			if paused:
				ui.show_pause()
			else:
				ui.hide_overlay()
			get_viewport().set_input_as_handled()
