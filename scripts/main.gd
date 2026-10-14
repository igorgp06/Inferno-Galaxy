extends Node2D

const PLAYER_SCENE = preload("res://scenes/player.tscn")
const ENEMY_SCENE = preload("res://scenes/enemy.tscn")
const BULLET_SCENE = preload("res://scenes/bullet.tscn")
const PICKUP_SCENE = preload("res://scenes/pickup.tscn")
const EFFECT_SCRIPT = preload("res://scripts/effect.gd")

@onready var entities: Node2D = $Entities
@onready var starfield: Node2D = $Starfield
@onready var audio = $Audio
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
	# Corrige o bug da v0.2.0: nao deixar os objetos herdar ALWAYS de Main.
	entities.process_mode = Node.PROCESS_MODE_PAUSABLE
	starfield.process_mode = Node.PROCESS_MODE_PAUSABLE
	get_tree().paused = false
	randomize()
	ui.start_requested.connect(start_game)
	ui.resume_requested.connect(resume_game)
	ui.volumes_changed.connect(_on_volumes_changed)
	ui.show_menu()
	_on_volumes_changed(ui.music_slider.value, ui.effects_slider.value)

func start_game() -> void:
	# Remove objetos antigos antes de reiniciar; nao duplica inimigos ou tiros.
	for child in entities.get_children():
		entities.remove_child(child)
		child.queue_free()
	get_tree().paused = false
	paused = false
	game_active = true
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
	player.boost_collected.connect(_on_boost_collected)
	ui.update_stats(score, lives, wave)
	ui.update_boost(0.0, 0.0)
	ui.hide_overlay()
	audio.start_music()

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
	enemy.hit.connect(_on_enemy_hit)

func _on_player_shoot(origin: Vector2, double_shot: bool) -> void:
	if not game_active or paused:
		return
	if double_shot:
		_spawn_bullet(origin + Vector2(-12, 0), true)
		_spawn_bullet(origin + Vector2(12, 0), true)
	else:
		_spawn_bullet(origin, true)
	audio.play_sound("laser")

func _on_enemy_shoot(origin: Vector2) -> void:
	if game_active and not paused:
		_spawn_bullet(origin, false)
		audio.play_sound("enemy_laser")

func _spawn_bullet(origin: Vector2, is_player_bullet: bool) -> void:
	var bullet = BULLET_SCENE.instantiate()
	bullet.configure(is_player_bullet)
	bullet.position = origin
	entities.add_child.call_deferred(bullet)

func _on_enemy_hit(place: Vector2) -> void:
	_spawn_effect(place, "hit")
	audio.play_sound("hit_enemy")

func _on_enemy_destroyed(points: int, drop_position: Vector2) -> void:
	if not game_active:
		return
	_spawn_effect(drop_position, "explosion")
	audio.play_sound("explosion")
	score += points
	kills += 1
	if kills % 7 == 0:
		_spawn_pickup(drop_position)
	var next_wave := 1 + int(kills / 12)
	if next_wave != wave:
		wave = next_wave
	ui.update_stats(score, lives, wave)

func _spawn_effect(effect_position: Vector2, kind: String) -> void:
	var effect = EFFECT_SCRIPT.new()
	effect.configure(kind)
	effect.position = effect_position
	entities.add_child.call_deferred(effect)

func _spawn_pickup(drop_position: Vector2) -> void:
	var pickup = PICKUP_SCENE.instantiate()
	pickup.boost_kind = int(kills / 7) % 2
	pickup.position = drop_position
	entities.add_child.call_deferred(pickup)

func _on_boost_collected(kind: int, place: Vector2) -> void:
	_spawn_effect(place, "boost")
	audio.play_sound("boost")

func _on_player_damaged() -> void:
	if not game_active:
		return
	lives -= 1
	if is_instance_valid(player):
		_spawn_effect(player.global_position, "damage")
	audio.play_sound("damage")
	ui.update_stats(score, lives, wave)
	if lives <= 0:
		_end_game()

func _end_game() -> void:
	game_active = false
	paused = false
	audio.stop_music()
	ui.show_game_over(score)
	get_tree().paused = true

func resume_game() -> void:
	if not game_active:
		return
	paused = false
	get_tree().paused = false
	ui.hide_overlay()

func _on_volumes_changed(music_value: float, effects_value: float) -> void:
	audio.apply_volumes(music_value, effects_value)

func _input(event: InputEvent) -> void:
	# _input em Main (ALWAYS) recebe Esc mesmo se o botao Continuar tem foco.
	if not game_active:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_P:
			if paused:
				resume_game()
			else:
				paused = true
				ui.show_pause()
				get_tree().paused = true
			get_viewport().set_input_as_handled()
