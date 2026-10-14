extends CanvasLayer

signal start_requested
signal resume_requested
signal volumes_changed(music_value: float, effects_value: float)

var overlay: ColorRect
var title_label: Label
var message_label: Label
var controls_label: Label
var main_button: Button
var score_label: Label
var lives_label: Label
var wave_label: Label
var boost_label: Label
var music_slider: HSlider
var effects_slider: HSlider
var volume_label_music: Label
var volume_label_effects: Label
var click_player: AudioStreamPlayer
var mode := "menu"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	score_label = _make_label("PONTOS 00000", 19, Color("e8faff"), Vector2(13, 10), Vector2(245, 30))
	lives_label = _make_label("VIDAS 3", 19, Color("ffb4c4"), Vector2(345, 10), Vector2(125, 30))
	wave_label = _make_label("ONDA 1", 17, Color("ffe4aa"), Vector2(13, 40), Vector2(180, 30))
	boost_label = _make_label("", 16, Color("77f1e6"), Vector2(13, 73), Vector2(445, 28))

	overlay = ColorRect.new()
	overlay.color = Color(0.017, 0.025, 0.065, 0.96)
	overlay.position = Vector2.ZERO
	overlay.size = Vector2(480, 720)
	add_child(overlay)

	title_label = _make_label("INFERNO GALAXY", 35, Color("66ecff"), Vector2(18, 153), Vector2(444, 56), overlay)
	message_label = _make_label("PROTOTIPO 0.2.1", 20, Color("eef4ff"), Vector2(30, 239), Vector2(420, 78), overlay)
	controls_label = _make_label("WASD / SETAS - MOVER\nESPACO / J - ATIRAR\nESC / P - PAUSAR", 18, Color("a9bfdc"), Vector2(35, 345), Vector2(410, 108), overlay)

	main_button = Button.new()
	main_button.text = "JOGAR"
	main_button.position = Vector2(130, 492)
	main_button.size = Vector2(220, 57)
	main_button.add_theme_font_size_override("font_size", 23)
	main_button.pressed.connect(_on_main_button_pressed)
	overlay.add_child(main_button)

	volume_label_music = _make_label("MUSICA", 15, Color("b9d2e7"), Vector2(18, 574), Vector2(118, 32), overlay)
	volume_label_effects = _make_label("EFEITOS", 15, Color("b9d2e7"), Vector2(18, 619), Vector2(118, 32), overlay)
	music_slider = _make_slider(Vector2(155, 579), 0.60)
	effects_slider = _make_slider(Vector2(155, 624), 0.75)
	music_slider.value_changed.connect(_on_volume_slider_changed)
	effects_slider.value_changed.connect(_on_volume_slider_changed)

	click_player = AudioStreamPlayer.new()
	click_player.stream = preload("res://assets/audio/click.wav")
	add_child(click_player)
	show_menu()

func _make_slider(pos: Vector2, default_value: float) -> HSlider:
	var slider := HSlider.new()
	slider.position = pos
	slider.size = Vector2(260, 25)
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = default_value
	overlay.add_child(slider)
	return slider

func _make_label(text_value: String, font_size: int, label_color: Color, pos: Vector2, dims: Vector2, parent_node: Node = null) -> Label:
	var label := Label.new()
	label.text = text_value
	label.position = pos
	label.size = dims
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", label_color)
	if parent_node == null:
		add_child(label)
	else:
		parent_node.add_child(label)
	return label

func update_stats(score: int, lives: int, wave: int) -> void:
	score_label.text = "PONTOS %05d" % score
	lives_label.text = "VIDAS %d" % lives
	wave_label.text = "ONDA %d" % wave

func update_boost(rapid: float, double_shot: float) -> void:
	if rapid > 0.0 and double_shot > 0.0:
		boost_label.text = "RAPIDO %.0fs  +  DUPLO %.0fs" % [rapid, double_shot]
	elif rapid > 0.0:
		boost_label.text = "BOOST: TIRO RAPIDO  %.0fs" % rapid
	elif double_shot > 0.0:
		boost_label.text = "BOOST: TIRO DUPLO  %.0fs" % double_shot
	else:
		boost_label.text = ""

func hide_overlay() -> void:
	overlay.visible = false

func _show_volume_controls(visible_controls: bool) -> void:
	volume_label_music.visible = visible_controls
	volume_label_effects.visible = visible_controls
	music_slider.visible = visible_controls
	effects_slider.visible = visible_controls

func show_menu() -> void:
	mode = "menu"
	overlay.visible = true
	title_label.text = "INFERNO GALAXY"
	message_label.text = "PROTOTIPO JOGAVEL 0.2.1\nDefenda a galaxia!"
	controls_label.visible = true
	main_button.text = "JOGAR"
	_show_volume_controls(true)

func show_pause() -> void:
	mode = "pause"
	overlay.visible = true
	title_label.text = "PAUSADO"
	message_label.text = "Jogo congelado. Esc para continuar."
	controls_label.visible = true
	main_button.text = "CONTINUAR"
	_show_volume_controls(true)

func show_game_over(final_score: int) -> void:
	mode = "gameover"
	overlay.visible = true
	title_label.text = "FIM DE JOGO"
	message_label.text = "Pontuacao final: %d\nTente novamente!" % final_score
	controls_label.visible = false
	main_button.text = "JOGAR DE NOVO"
	_show_volume_controls(true)

func _on_volume_slider_changed(_value: float) -> void:
	click_player.volume_db = -80.0 if effects_slider.value <= 0.001 else linear_to_db(effects_slider.value) - 8.0
	volumes_changed.emit(music_slider.value, effects_slider.value)

func _on_main_button_pressed() -> void:
	click_player.volume_db = -80.0 if effects_slider.value <= 0.001 else linear_to_db(effects_slider.value) - 8.0
	click_player.play()
	if mode == "pause":
		resume_requested.emit()
	else:
		start_requested.emit()
