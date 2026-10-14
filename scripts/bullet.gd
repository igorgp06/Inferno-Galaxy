extends Area2D

var from_player := true
var speed := 570.0
var travel_direction := Vector2.UP

func configure(is_from_player: bool, direction: Vector2 = Vector2.DOWN, custom_speed: float = 0.0) -> void:
	from_player = is_from_player
	travel_direction = Vector2.UP if from_player else direction.normalized()
	speed = custom_speed if custom_speed > 0.0 else (570.0 if from_player else 210.0)

func _ready() -> void:
	if from_player:
		collision_layer = 4
		collision_mask = 2
		area_entered.connect(_on_area_entered)
	else:
		collision_layer = 8
		collision_mask = 0
		add_to_group("enemy_bullets")

func _physics_process(delta: float) -> void:
	position += travel_direction * speed * delta
	if position.y < -35.0 or position.y > 755.0 or position.x < -35.0 or position.x > 515.0:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if not is_queued_for_deletion() and not area.is_queued_for_deletion() and area.is_in_group("enemies"):
		area.call("take_damage", 1)
		queue_free()

func _draw() -> void:
	var color := Color("54ecf5") if from_player else Color("ff7885")
	if from_player:
		draw_rect(Rect2(-3, -10, 6, 20), color)
		draw_rect(Rect2(-1, -13, 2, 26), Color(1, 1, 1, 0.55))
	else:
		# Rotaciona apenas o desenho, nao a colisao circular.
		draw_set_transform(Vector2.ZERO, travel_direction.angle() - PI / 2.0)
		draw_rect(Rect2(-3, -10, 6, 20), color)
		draw_rect(Rect2(-1, -13, 2, 26), Color(1, 1, 1, 0.55))
		draw_set_transform(Vector2.ZERO)
