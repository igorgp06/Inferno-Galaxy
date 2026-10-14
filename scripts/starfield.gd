extends Node2D

const WIDTH := 480.0
const HEIGHT := 720.0
var stars: Array[Dictionary] = []

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261014
	for i in range(95):
		stars.append({
			"position": Vector2(rng.randf_range(0.0, WIDTH), rng.randf_range(0.0, HEIGHT)),
			"speed": rng.randf_range(24.0, 100.0),
			"radius": rng.randf_range(0.8, 2.0)
		})

func _process(delta: float) -> void:
	for i in range(stars.size()):
		var p: Vector2 = stars[i]["position"]
		p.y += float(stars[i]["speed"]) * delta
		if p.y > HEIGHT:
			p.y = 0.0
		stars[i]["position"] = p
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(WIDTH, HEIGHT)), Color("080e24"))
	draw_circle(Vector2(115, 180), 120.0, Color(0.32, 0.10, 0.45, 0.13))
	draw_circle(Vector2(375, 490), 160.0, Color(0.04, 0.52, 0.64, 0.08))
	for star in stars:
		var p: Vector2 = star["position"]
		var radius: float = star["radius"]
		draw_circle(p, radius, Color(0.72, 0.91, 1.0, 0.8))
