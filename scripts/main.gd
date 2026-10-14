extends Node2D

const PLAYER_SCENE = preload("res://scenes/player.tscn")
const ENEMY_SCENE = preload("res://scenes/enemy.tscn")
const BOSS_SCENE = preload("res://scenes/boss.tscn")
const BULLET_SCENE = preload("res://scenes/bullet.tscn")
const PICKUP_SCENE = preload("res://scenes/pickup.tscn")
const EFFECT_SCRIPT = preload("res://scripts/effect.gd")

const WAVE_DURATIONS := [18.0, 22.0, 24.0]
const WAVE_SPAWN_INTERVALS := [1.35, 1.10, 0.95]
const TOTAL_WAVES := 3

@onready var entities: Node2D = $Entities
@onready var starfield: Node2D = $Starfield
@onready var audio = $Audio
@onready var ui = $UI

var player = null
var boss = null
var score := 0
var lives := 3
var wave := 1
var kills := 0
var spawn_timer := 0.0
var wave_elapsed := 0.0
var transition_remaining := -1.0
var announcement_remaining := 0.0
var boss_fight := false
var game_active := false
var paused := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Apenas Main e UI continuam processando durante a pausa.
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
	get_tree().paused = false
	for child in entities.get_children():
		entities.remove_child(child)
		child.queue_free()
	paused = false
	game_active = true
	boss_fight = false
	boss = null
	score = 0
	lives = 3
	kills = 0
	transition_remaining = -1.0
	announcement_remaining = 0.0
	player = PLAYER_SCENE.instantiate()
	player.position = Vector2(240.0, 615.0)
	entities.add_child(player)
	player.shoot_requested.connect(_on_player_shoot)
	player.damaged.connect(_on_player_damaged)
	player.boost_collected.connect(_on_boost_collected)
	ui.hide_overlay()
	ui.hide_boss_health()
	ui.update_boost(0.0, 0.0)
	_begin_wave(1)
	audio.start_music()

func _process(delta: float) -> void:
	if not game_active or paused:
		return
	if announcement_remaining > 0.0:
		announcement_remaining -= delta
		if announcement_remaining <= 0.0:
			ui.hide_announcement()
	if is_instance_valid(player):
		ui.update_boost(player.rapid_remaining, player.double_remaining)
	if boss_fight:
		ui.update_time_info("ENFRENTE O CHEFE")
		return
	if transition_remaining >= 0.0:
		ui.update_time_info("PROXIMA ETAPA...")
		transition_remaining -= delta
		if transition_remaining < 0.0:
			if wave < TOTAL_WAVES:
				_begin_wave(wave + 1)
			else:
				_begin_boss_fight()
		return
	wave_elapsed += delta
	ui.update_time_info("TEMPO %02ds" % ceili(maxf(0.0, WAVE_DURATIONS[wave - 1] - wave_elapsed)))
	if wave_elapsed >= WAVE_DURATIONS[wave - 1]:
		_complete_wave()
		return
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		_spawn_enemy()
		spawn_timer = WAVE_SPAWN_INTERVALS[wave - 1]

func _begin_wave(number: int) -> void:
	wave = number
	wave_elapsed = 0.0
	spawn_timer = 0.7
	transition_remaining = -1.0
	ui.update_stats(score, lives, wave)
	ui.update_time_info("TEMPO %02ds" % ceili(WAVE_DURATIONS[wave - 1]))
	_show_announcement("ONDA %d / %d" % [wave, TOTAL_WAVES], 2.2)

func _complete_wave() -> void:
	transition_remaining = 3.0
	_clear_hostiles()
	if wave < TOTAL_WAVES:
		_show_announcement("ONDA %d CONCLUIDA" % wave, 2.2)
	else:
		_show_announcement("ALERTA: CHEFE A CAMINHO", 2.6)

func _clear_hostiles() -> void:
	for child in entities.get_children():
		if child.is_in_group("enemies") or child.is_in_group("enemy_bullets"):
			child.queue_free()

func _choose_enemy_kind() -> int:
	var roll := randi_range(0, 99)
	if wave == 1:
		return 0 if roll < 75 else 1
	if wave == 2:
		return 0 if roll < 45 else (1 if roll < 83 else 2)
	return 0 if roll < 24 else (1 if roll < 63 else 2)

func _spawn_enemy() -> void:
	var enemy = ENEMY_SCENE.instantiate()
	enemy.configure(_choose_enemy_kind(), wave)
	enemy.position = Vector2(randf_range(40.0, 440.0), -35.0)
	entities.add_child(enemy)
	enemy.destroyed.connect(_on_enemy_destroyed)
	enemy.shoot_requested.connect(_on_enemy_shoot)
	enemy.hit.connect(_on_enemy_hit)

func _begin_boss_fight() -> void:
	transition_remaining = -1.0
	_clear_hostiles()
	boss_fight = true
	boss = BOSS_SCENE.instantiate()
	boss.position = Vector2(240.0, -80.0)
	boss.health_changed.connect(_on_boss_health_changed)
	boss.hit.connect(_on_enemy_hit)
	boss.barrage_requested.connect(_on_boss_barrage)
	boss.destroyed.connect(_on_boss_destroyed)
	entities.add_child(boss)
	ui.show_boss_health(boss.hp, boss.hp)
	ui.update_stats(score, lives, wave)
	_show_announcement("GUARDIAO DO SETOR", 3.0)

func _on_boss_health_changed(current: int, maximum: int) -> void:
	if game_active:
		ui.show_boss_health(current, maximum)

func _on_boss_barrage(origin: Vector2, wide: bool) -> void:
	if not game_active or paused:
		return
	var direction := Vector2.DOWN
	if is_instance_valid(player):
		direction = (player.global_position - origin).normalized()
	var offsets := [-0.49, -0.25, 0.0, 0.25, 0.49] if wide else [-0.28, 0.0, 0.28]
	for offset in offsets:
		_spawn_bullet(origin, false, direction.rotated(offset), 250.0)
	audio.play_sound("enemy_laser")

func _on_boss_destroyed(points: int, place: Vector2) -> void:
	if not game_active:
		return
	score += points
	ui.update_stats(score, lives, wave)
	audio.play_sound("explosion")
	_spawn_effect(place, "explosion")
	_spawn_effect(place + Vector2(-42, 8), "explosion")
	_spawn_effect(place + Vector2(42, -5), "explosion")
	boss_fight = false
	boss = null
	_finish_game(true)

func _on_player_shoot(origin: Vector2, double_shot: bool) -> void:
	if not game_active or paused:
		return
	if double_shot:
		_spawn_bullet(origin + Vector2(-12.0, 0.0), true)
		_spawn_bullet(origin + Vector2(12.0, 0.0), true)
	else:
		_spawn_bullet(origin, true)
	audio.play_sound("laser")

func _on_enemy_shoot(origin: Vector2) -> void:
	if game_active and not paused:
		_spawn_bullet(origin, false)
		audio.play_sound("enemy_laser")

func _spawn_bullet(origin: Vector2, is_player_bullet: bool, direction: Vector2 = Vector2.DOWN, speed_override: float = 0.0) -> void:
	var bullet = BULLET_SCENE.instantiate()
	bullet.configure(is_player_bullet, direction, speed_override)
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

func _on_boost_collected(_kind: int, place: Vector2) -> void:
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
		_finish_game(false)

func _finish_game(victory: bool) -> void:
	game_active = false
	paused = false
	audio.stop_music()
	ui.hide_boss_health()
	ui.hide_announcement()
	if victory:
		ui.show_victory(score, lives)
	else:
		ui.show_game_over(score)
	get_tree().paused = true

func _show_announcement(text_value: String, duration: float) -> void:
	ui.show_announcement(text_value)
	announcement_remaining = duration

func resume_game() -> void:
	if not game_active:
		return
	paused = false
	get_tree().paused = false
	ui.hide_overlay()

func _on_volumes_changed(music_value: float, effects_value: float) -> void:
	audio.apply_volumes(music_value, effects_value)

func _input(event: InputEvent) -> void:
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
