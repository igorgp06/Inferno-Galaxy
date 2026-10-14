extends Area2D

const RAPID_TEXTURE = preload("res://assets/sprites/boost_rapid.png")
const DOUBLE_TEXTURE = preload("res://assets/sprites/boost_double.png")

var boost_kind := 0
var elapsed := 0.0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_to_group("pickups")

func _physics_process(delta: float) -> void:
	elapsed += delta
	position.y += 115.0 * delta
	if position.y > 755.0:
		queue_free()
	queue_redraw()

func _draw() -> void:
	var texture = RAPID_TEXTURE if boost_kind == 0 else DOUBLE_TEXTURE
	var pulse := 1.0 + sin(elapsed * 5.0) * 0.07
	var width := 42.0 * pulse
	draw_texture_rect(texture, Rect2(-width * 0.5, -width * 0.5, width, width), false)
