extends Node

const SOUND_FILES := {
	"laser": preload("res://assets/audio/laser.wav"),
	"enemy_laser": preload("res://assets/audio/enemy_laser.wav"),
	"explosion": preload("res://assets/audio/explosion.wav"),
	"damage": preload("res://assets/audio/damage.wav"),
	"boost": preload("res://assets/audio/boost.wav"),
	"hit_enemy": preload("res://assets/audio/hit_enemy.wav")
}
const SOUND_LEVELS := {
	"laser": -8.0,
	"enemy_laser": -18.0,
	"explosion": -5.0,
	"damage": -4.0,
	"boost": -4.0,
	"hit_enemy": -11.0
}

var players: Dictionary = {}
var next_player: Dictionary = {}
var music_player: AudioStreamPlayer
var music_enabled := false
var music_volume := 0.4
var effects_volume := 0.75

func _ready() -> void:
	# Diferente do Menu, este gerenciador DEVE parar enquanto o jogo pausa.
	process_mode = Node.PROCESS_MODE_PAUSABLE
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.stream = preload("res://assets/audio/DavidKBD - InterstellarPack - 01 - Interstellar.ogg")
	music_player.finished.connect(_on_music_finished)
	add_child(music_player)
	for sound_name in SOUND_FILES:
		var voices: Array[AudioStreamPlayer] = []
		var voice_count := 4 if sound_name == "laser" else 2
		for i in range(voice_count):
			var voice := AudioStreamPlayer.new()
			voice.name = "%s_%d" % [sound_name, i]
			voice.stream = SOUND_FILES[sound_name]
			add_child(voice)
			voices.append(voice)
		players[sound_name] = voices
		next_player[sound_name] = 0
	apply_volumes(music_volume, effects_volume)

func apply_volumes(music_value: float, effects_value: float) -> void:
	music_volume = clampf(music_value, 0.0, 1.0)
	effects_volume = clampf(effects_value, 0.0, 1.0)
	music_player.volume_db = _volume_db(music_volume, -12.0)
	for sound_name in players:
		for voice in players[sound_name]:
			voice.volume_db = _volume_db(effects_volume, float(SOUND_LEVELS[sound_name]))

func _volume_db(value: float, offset: float) -> float:
	if value <= 0.001:
		return -80.0
	return linear_to_db(value) + offset

func play_sound(sound_name: String) -> void:
	if not players.has(sound_name):
		return
	var voices: Array = players[sound_name]
	var index: int = next_player[sound_name]
	for i in range(voices.size()):
		var candidate_index := (index + i) % voices.size()
		if not voices[candidate_index].playing:
			index = candidate_index
			break
	var selected: AudioStreamPlayer = voices[index]
	selected.play()
	next_player[sound_name] = (index + 1) % voices.size()

func start_music() -> void:
	music_enabled = true
	music_player.stop()
	music_player.play()

func stop_music() -> void:
	music_enabled = false
	music_player.stop()

func _on_music_finished() -> void:
	if music_enabled:
		music_player.play()
