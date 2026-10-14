extends Node2D

var kind := "explosion"
var age := 0.0
var duration := 0.50
var color := Color("ff8478")
var rays: Array[Vector2] = []

func configure(effect_kind: String) -> void:
	kind = effect_kind
	match kind:
		"explosion":
			duration = 0.54
			color = Color("ffb16a")
		"damage":
			duration = 0.64
			color = Color("ff5e76")
		"boost":
			duration = 0.70
			color = Color("6cfaed")
		"hit":
			duration = 0.22
			color = Color("fff8da")
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in range(11):
		var angle := float(i) * TAU / 11.0 + rng.randf_range(-0.18, 0.18)
		rays.append(Vector2.RIGHT.rotated(angle) * rng.randf_range(0.65, 1.25))

func _process(delta: float) -> void:
	age += delta
	if age >= duration:
		queue_free()
	else:
		queue_redraw()

func _draw() -> void:
	var t := clampf(age / duration, 0.0, 1.0)
	var alpha := 1.0 - t
	var outward := 9.0 + 26.0 * t
	var central := 19.0 * (1.0 - t) if kind == "explosion" else 12.0 * (1.0 - t)
	if central > 0.0:
		draw_circle(Vector2.ZERO, central, Color(color.r, color.g, color.b, alpha * 0.45))
	var ring_radius := 6.0 + t * (32.0 if kind == "boost" else 19.0)
	draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 26, Color(color.r, color.g, color.b, alpha * 0.75), 2.8)
	if kind != "boost":
		for ray in rays:
			var a := ray * outward
			var b := ray * (outward + 11.0 * alpha)
			draw_line(a, b, Color(color.r, color.g, color.b, alpha), 2.6)
	else:
		for ray in rays:
			draw_circle(ray * outward, 2.8 * alpha, Color(0.8, 1.0, 0.94, alpha))
