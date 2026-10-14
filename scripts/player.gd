extends Area2D

signal shoot_requested(origin: Vector2, double_shot: bool)
signal damaged

@export var speed: float = 305.0
var rapid_remaining := 0.0
var double_remaining := 0.0
var invincible_remaining := 0.0
var shoot_timer := 0.0

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	# Setas: acoes padrao da Godot. WASD: verificacao adicional.
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var wasd := Vector2(
		float(int(Input.is_key_pressed(KEY_D)) - int(Input.is_key_pressed(KEY_A))),
		float(int(Input.is_key_pressed(KEY_S)) - int(Input.is_key_pressed(KEY_W)))
	)
	direction = (direction + wasd).normalized()
	position += direction * speed * delta
	position.x = clampf(position.x, 25.0, 455.0)
	position.y = clampf(position.y, 110.0, 680.0)

	rapid_remaining = maxf(0.0, rapid_remaining - delta)
	double_remaining = maxf(0.0, double_remaining - delta)
	invincible_remaining = maxf(0.0, invincible_remaining - delta)
	shoot_timer -= delta

	if (Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_J)) and shoot_timer <= 0.0:
		shoot_requested.emit(global_position + Vector2(0.0, -25.0), double_remaining > 0.0)
		shoot_timer = 0.10 if rapid_remaining > 0.0 else 0.23
	queue_redraw()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("pickups"):
		if int(area.get("boost_kind")) == 0:
			rapid_remaining = 8.0
		else:
			double_remaining = 8.0
		area.queue_free()
		return

	if area.is_in_group("enemy_bullets"):
		area.queue_free()
		_take_hit()
	elif area.is_in_group("enemies"):
		area.queue_free()
		_take_hit()

func _take_hit() -> void:
	if invincible_remaining > 0.0:
		return
	invincible_remaining = 1.2
	damaged.emit()

func _draw() -> void:
	# Pisca brevemente quando perde uma vida.
	if invincible_remaining > 0.0 and int(invincible_remaining * 12.0) % 2 == 0:
		return
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -26), Vector2(21, 19), Vector2(5, 12),
		Vector2(0, 18), Vector2(-5, 12), Vector2(-21, 19)
	]), Color("32e1e8"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -17), Vector2(8, 11), Vector2(-8, 11)
	]), Color("d7f9ff"))
	draw_rect(Rect2(-15, 18, 8, 11), Color("ff9c54"))
	draw_rect(Rect2(7, 18, 8, 11), Color("ff9c54"))
