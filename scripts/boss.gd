extends Area2D

const BOSS_TEXTURE = preload("res://assets/sprites/boss_guardian.png")

signal destroyed(points: int, place: Vector2)
signal hit(place: Vector2)
signal health_changed(current: int, maximum: int)
signal barrage_requested(origin: Vector2, wide: bool)

const MAX_HP := 38
const BOSS_POINTS := 2500

var hp := MAX_HP
var elapsed := 0.0
var shoot_timer := 1.5
var volley_count := 0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_to_group("enemies")
	add_to_group("bosses")
	health_changed.emit(hp, MAX_HP)

func _physics_process(delta: float) -> void:
	if position.y < 125.0:
		position.y = minf(125.0, position.y + 95.0 * delta)
		return
	elapsed += delta
	position.x = 240.0 + sin(elapsed * 1.05) * 138.0
	shoot_timer -= delta
	if shoot_timer <= 0.0:
		volley_count += 1
		barrage_requested.emit(global_position + Vector2(0.0, 34.0), volley_count % 3 == 0)
		shoot_timer = 1.45

func take_damage(amount: int = 1) -> void:
	if hp <= 0 or is_queued_for_deletion():
		return
	hp = maxi(0, hp - amount)
	health_changed.emit(hp, MAX_HP)
	if hp == 0:
		destroyed.emit(BOSS_POINTS, global_position)
		queue_free()
	else:
		hit.emit(global_position + Vector2(randf_range(-25.0, 25.0), randf_range(-15.0, 15.0)))
		queue_redraw()

func _draw() -> void:
	draw_texture_rect(BOSS_TEXTURE, Rect2(-76, -48, 152, 96), false)
