extends Area2D

signal destroyed(points: int, place: Vector2)
signal shoot_requested(origin: Vector2)
signal hit(place: Vector2)

var enemy_kind := 0
var wave := 1
var hp := 1
var points := 100
var fall_speed := 120.0
var base_x := 0.0
var elapsed := 0.0
var shoot_timer := 2.0

func configure(kind: int, current_wave: int) -> void:
	enemy_kind = kind
	wave = current_wave
	match enemy_kind:
		0:
			hp = 1
			fall_speed = 135.0 + wave * 6.0
			points = 100
		1:
			hp = 2
			fall_speed = 108.0 + wave * 5.0
			points = 200
		2:
			hp = 3
			fall_speed = 78.0 + wave * 4.0
			points = 300

func _ready() -> void:
	add_to_group("enemies")
	base_x = position.x
	shoot_timer = randf_range(1.2, 2.7)

func _physics_process(delta: float) -> void:
	elapsed += delta
	position.y += fall_speed * delta
	match enemy_kind:
		1:
			position.x = base_x + sin(elapsed * 3.4) * 48.0
		2:
			position.x = base_x + sin(elapsed * 1.8) * 32.0
	position.x = clampf(position.x, 24.0, 456.0)

	shoot_timer -= delta
	if shoot_timer <= 0.0 and position.y > 5.0 and position.y < 615.0:
		shoot_requested.emit(global_position + Vector2(0, 18))
		shoot_timer = randf_range(1.7, 3.0) if enemy_kind == 0 else randf_range(1.0, 2.1)
	if position.y > 765.0:
		queue_free()

func take_damage(amount: int = 1) -> void:
	if is_queued_for_deletion():
		return
	hp -= amount
	if hp <= 0:
		destroyed.emit(points, global_position)
		queue_free()
	else:
		hit.emit(global_position)
		queue_redraw()

func _draw() -> void:
	var main_color := Color("ff5e76")
	if enemy_kind == 1:
		main_color = Color("ffba54")
	elif enemy_kind == 2:
		main_color = Color("b58cff")
	draw_colored_polygon(PackedVector2Array([
		Vector2(-21, -13), Vector2(-8, -4), Vector2(0, -12),
		Vector2(8, -4), Vector2(21, -13), Vector2(16, 17),
		Vector2(0, 9), Vector2(-16, 17)
	]), main_color)
	draw_circle(Vector2(0, 2), 7.0, Color("1a1638"))
	if enemy_kind == 2:
		draw_rect(Rect2(-14, -16, 28, 5), Color("ece0ff"))
