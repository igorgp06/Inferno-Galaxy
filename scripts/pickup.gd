extends Area2D

var boost_kind := 0
var elapsed := 0.0

func _ready() -> void:
	add_to_group("pickups")

func _physics_process(delta: float) -> void:
	elapsed += delta
	position.y += 115.0 * delta
	if position.y > 755.0:
		queue_free()
	queue_redraw()

func _draw() -> void:
	var c := Color("6cfaed") if boost_kind == 0 else Color("ffdc71")
	var size_offset := sin(elapsed * 5.0) * 1.5
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -15 - size_offset), Vector2(15 + size_offset, 0),
		Vector2(0, 15 + size_offset), Vector2(-15 - size_offset, 0)
	]), c)
	draw_circle(Vector2.ZERO, 5.0, Color("16213d"))
