extends Node

const SOUND_FILES := {
	"laser": preload("res://assets/audio/laser.wav"),
	"enemy_laser": preload("res://assets/audio/enemy_laser.wav"),
	"explosion": preload("res://assets/audio/explosion.wav"),
	"damage": preload("res://assets/audio/damage.wav"),
	"boost": preload("res://assets/audio/boost.wav"),
	"hit_enemy": preload("res://assets/audio/hit_enemy.wav")
}

const MUSIC_TRACKS := [
	preload("res://assets/audio/interstellar_pack/DavidKBD - InterstellarPack - 01 - Interstellar.ogg"),
	preload("res://assets/audio/interstellar_pack/DavidKBD - InterstellarPack - 02 - Plasma Storm.ogg"),
	preload("res://assets/audio/interstellar_pack/DavidKBD - InterstellarPack - 04 - Horsehead Nebula.ogg"),
	preload("res://assets/audio/interstellar_pack/DavidKBD - InterstellarPack - 05 - Forgotten Station.ogg"),
	preload("res://assets/audio/interstellar_pack/DavidKBD - InterstellarPack - 06 - Hope on the Horizon.ogg"),
	preload("res://assets/audio/interstellar_pack/DavidKBD - InterstellarPack - 07 - Electric Firework.ogg"),
	preload("res://assets/audio/interstellar_pack/DavidKBD - InterstellarPack - 08 - Synth Kobra.ogg"),
	preload("res://assets/audio/interstellar_pack/DavidKBD - InterstellarPack - 09 - Spiral of Plasma.ogg"),
]

const MUSIC_TITLES := [
	"Interstellar", "Plasma Storm", "Horsehead Nebula", "Forgotten Station",
	"Hope on the Horizon", "Electric Firework", "Synth Kobra", "Spiral of Plasma"
]

const BOSS_THEMES := {
	"sector_guardian": preload("res://assets/audio/interstellar_pack/DavidKBD - InterstellarPack - 03 - Temple of Madness.ogg")
}
const BOSS_TITLES := {"sector_guardian": "Temple of Madness"}
const CROSSFADE_SECONDS := 1.8

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
var boss_player: AudioStreamPlayer
var shuffled_track_indices: Array[int] = []
var previous_track_index := -1
var music_enabled := false
var music_mode := "normal"
var music_volume := 0.4
var effects_volume := 0.75
var normal_gain := 1.0
var boss_gain := 0.0
var crossfade_elapsed := 0.0
var crossfade_running := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	music_player = AudioStreamPlayer.new()
	music_player.name = "NormalMusic"
	for track in MUSIC_TRACKS:
		if track is AudioStreamOggVorbis:
			track.loop = false
	music_player.finished.connect(_on_normal_track_finished)
	add_child(music_player)

	boss_player = AudioStreamPlayer.new()
	boss_player.name = "BossMusic"
	add_child(boss_player)

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

func _process(delta: float) -> void:
	if not crossfade_running:
		return
	crossfade_elapsed += delta
	var t := clampf(crossfade_elapsed / CROSSFADE_SECONDS, 0.0, 1.0)
	if music_mode == "boss":
		normal_gain = cos(t * PI * 0.5)
		boss_gain = sin(t * PI * 0.5)
	else:
		normal_gain = sin(t * PI * 0.5)
		boss_gain = cos(t * PI * 0.5)
	_apply_music_volumes()
	if t >= 1.0:
		crossfade_running = false
		if music_mode == "boss":
			music_player.stop()
		else:
			boss_player.stop()

func apply_volumes(music_value: float, effects_value: float) -> void:
	music_volume = clampf(music_value, 0.0, 1.0)
	effects_volume = clampf(effects_value, 0.0, 1.0)
	_apply_music_volumes()
	for sound_name in players:
		for voice in players[sound_name]:
			voice.volume_db = _volume_db(effects_volume, float(SOUND_LEVELS[sound_name]))

func _apply_music_volumes() -> void:
	if is_instance_valid(music_player):
		music_player.volume_db = _volume_db(music_volume * normal_gain, -12.0)
	if is_instance_valid(boss_player):
		boss_player.volume_db = _volume_db(music_volume * boss_gain, -12.0)

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
	music_player.stop()
	boss_player.stop()
	music_enabled = true
	music_mode = "normal"
	crossfade_running = false
	crossfade_elapsed = 0.0
	normal_gain = 1.0
	boss_gain = 0.0
	shuffled_track_indices.clear()
	previous_track_index = -1
	_apply_music_volumes()
	_play_next_track()

func play_boss_music(boss_id: String = "sector_guardian") -> void:
	if not music_enabled or not BOSS_THEMES.has(boss_id) or music_mode == "boss":
		return
	var theme: AudioStream = BOSS_THEMES[boss_id]
	if theme is AudioStreamOggVorbis:
		theme.loop = true
	boss_player.stop()
	boss_player.stream = theme
	boss_player.volume_db = -80.0
	boss_player.play()
	music_mode = "boss"
	crossfade_elapsed = 0.0
	crossfade_running = true
	normal_gain = 1.0
	boss_gain = 0.0
	_apply_music_volumes()
	print("[Inferno Galaxy] Tema do chefe: ", BOSS_TITLES[boss_id])

func return_to_normal_music() -> void:
	if not music_enabled or music_mode != "boss":
		return
	music_mode = "normal"
	crossfade_elapsed = 0.0
	crossfade_running = true
	normal_gain = 0.0
	boss_gain = 1.0
	_play_next_track()
	_apply_music_volumes()

func stop_music() -> void:
	music_enabled = false
	crossfade_running = false
	music_player.stop()
	boss_player.stop()

func _on_normal_track_finished() -> void:
	if music_enabled and music_mode == "normal":
		_play_next_track()

func _play_next_track() -> void:
	if not music_enabled or MUSIC_TRACKS.is_empty():
		return
	if shuffled_track_indices.is_empty():
		_shuffle_playlist()
	var next_index: int = shuffled_track_indices.pop_back()
	previous_track_index = next_index
	music_player.stream = MUSIC_TRACKS[next_index]
	music_player.play()
	print("[Inferno Galaxy] Tocando: ", MUSIC_TITLES[next_index])

func _shuffle_playlist() -> void:
	shuffled_track_indices.clear()
	for i in range(MUSIC_TRACKS.size()):
		shuffled_track_indices.append(i)
	shuffled_track_indices.shuffle()
	if shuffled_track_indices.size() > 1 and shuffled_track_indices.back() == previous_track_index:
		var first: int = shuffled_track_indices[0]
		shuffled_track_indices[0] = shuffled_track_indices[shuffled_track_indices.size() - 1]
		shuffled_track_indices[shuffled_track_indices.size() - 1] = first
