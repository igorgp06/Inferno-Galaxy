extends Area2D

var from_player := true
var speed := 570.0

func configure(is_from_player: bool) -> void:
	from_player = is_from_player

func _ready() -> void:
	if from_player:
		collision_layer = 4
		collision_mask = 2
		area_entered.connect(_on_area_entered)
	else:
		collision_layer = 8
		collision_mask = 0
		add_to_group("enemy_bullets")
		speed = 210.0

func _physics_process(delta: float) -> void:
	position.y += (-speed if from_player else speed) * delta
	if position.y < -35.0 or position.y > 755.0:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if not is_queued_for_deletion() and not area.is_queued_for_deletion() and area.is_in_group("enemies"):
		area.call("take_damage", 1)
		queue_free()

func _draw() -> void:
	var color := Color("54ecf5") if from_player else Color("ff7885")
	draw_rect(Rect2(-3, -10, 6, 20), color)
	draw_rect(Rect2(-1, -13, 2, 26), Color(1, 1, 1, 0.55))
