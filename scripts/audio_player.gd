class_name TetrixAudioPlayer
extends Node

const SAMPLE_RATE: int = 44100
const TEMPO_BPM: float = 149.0
const AMPLITUDE: float = 0.18
const FADE_DURATION_MS: int = 200
const FRAME_BATCH: int = 512

var enabled: bool = true
var playing: bool = true

var _stream_player: AudioStreamPlayer
var _sample_index: int = 0
var _note_index: int = 0
var _note_sample_position: int = 0
var _current_melody: Array = []
var _last_enabled: bool = true
var _last_playing: bool = true
var _fade_volume: float = 1.0
var _fade_samples_remaining: int = 0

const SAMPLES_PER_BEAT: int = int(float(SAMPLE_RATE) * 60.0 / TEMPO_BPM)

const NOTE := {
	"C3": 130.81,
	"D3": 146.83,
	"E3": 164.81,
	"F3": 174.61,
	"G3": 196.0,
	"A3": 220.0,
	"B3": 246.94,
	"C4": 261.63,
	"D4": 293.66,
	"E4": 329.63,
	"F4": 349.23,
	"G4": 392.0,
	"A4": 440.0,
	"B4": 493.88,
	"C5": 523.25,
	"D5": 587.33,
	"E5": 659.25,
	"F5": 698.46,
	"G5": 783.99,
	"A5": 880.0,
	"B5": 987.77,
	"REST": 0.0,
}

var _melody: Array = []
var _jingle_bells_melody: Array = []

func _ready() -> void:
	_last_enabled = enabled
	_last_playing = playing
	_fade_volume = 1.0 if enabled and playing else 0.0
	_setup_melodies()
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = SAMPLE_RATE
	stream.buffer_length = 0.25

	_stream_player = AudioStreamPlayer.new()
	_stream_player.bus = "Master"
	_stream_player.stream = stream
	add_child(_stream_player)
	_stream_player.play()
	_select_melody()
	set_process(true)

func start() -> void:
	if _stream_player and not _stream_player.playing:
		_stream_player.play()

func deinit() -> void:
	queue_free()

func _exit_tree() -> void:
	if _stream_player != null and _stream_player.playing:
		_stream_player.stop()

func play_music() -> void:
	if enabled:
		playing = true
	if not is_inside_tree():
		_last_playing = playing

func stop_music() -> void:
	playing = false
	if not is_inside_tree():
		_last_playing = playing

func toggle_music() -> void:
	set_enabled(not enabled)
	if enabled:
		playing = true

func set_enabled(value: bool) -> void:
	enabled = value
	if not enabled:
		playing = false
	if not is_inside_tree():
		_last_enabled = enabled
		_last_playing = playing
		_fade_volume = 1.0 if enabled and playing else 0.0

func is_enabled() -> bool:
	return enabled

func update_audio() -> void:
	pass

func _process(_delta: float) -> void:
	if _stream_player == null:
		return
	var playback: AudioStreamGeneratorPlayback = _stream_player.get_stream_playback()
	if playback == null:
		return

	if enabled != _last_enabled or playing != _last_playing:
		var fade_samples := int(FADE_DURATION_MS * SAMPLE_RATE / 1000)
		_fade_samples_remaining = maxi(fade_samples, 1)
		if enabled and playing:
			_fade_volume = 0.0
		else:
			_fade_volume = 1.0
		_last_enabled = enabled
		_last_playing = playing

	while playback.can_push_buffer(FRAME_BATCH):
		var frames := PackedVector2Array()
		frames.resize(FRAME_BATCH)
		for i in FRAME_BATCH:
			var sample := _generate_sample()
			frames[i] = Vector2(sample, sample)
		playback.push_buffer(frames)

func _generate_sample() -> float:
	if _current_melody.is_empty():
		return 0.0

	if _note_index >= _current_melody.size():
		_note_index = 0
		_note_sample_position = 0
		_sample_index = 0

	var note: Dictionary = _current_melody[_note_index]
	var frequency: float = note["freq"]
	var note_samples: int = int(float(note["duration"]) * float(SAMPLES_PER_BEAT))
	note_samples = maxi(note_samples, 1)
	var fade_samples: int = mini(note_samples / 10, 400)
	fade_samples = maxi(fade_samples, 1)

	var envelope: float = 1.0
	if _note_sample_position < fade_samples:
		envelope = float(_note_sample_position) / float(fade_samples)
	elif _note_sample_position > note_samples - fade_samples:
		var remaining: int = maxi(note_samples - _note_sample_position, 0)
		envelope = float(remaining) / float(fade_samples)

	if _fade_samples_remaining > 0:
		var fade_total: int = maxi(int(FADE_DURATION_MS * SAMPLE_RATE / 1000), 1)
		var fade_progress: float = 1.0 - (float(_fade_samples_remaining) / float(fade_total))
		var cosine_fade: float = 0.5 * (1.0 - cos(fade_progress * PI))
		if enabled and playing:
			_fade_volume = cosine_fade
		else:
			_fade_volume = 1.0 - cosine_fade
		_fade_samples_remaining -= 1
	else:
		_fade_volume = 1.0 if enabled and playing else 0.0

	var sample := 0.0
	if frequency > 0.0:
		var phase := float(_sample_index) * frequency / float(SAMPLE_RATE)
		sample = sin(phase * TAU) * AMPLITUDE * envelope
	sample *= _fade_volume

	_sample_index += 1
	_note_sample_position += 1
	if _note_sample_position >= note_samples:
		_note_sample_position = 0
		_note_index = (_note_index + 1) % _current_melody.size()

	return sample

func _select_melody() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var use_jingle := rng.randi_range(0, 14) == 0
	_current_melody = _jingle_bells_melody if use_jingle else _melody
	_note_index = 0
	_note_sample_position = 0
	_sample_index = 0

func _n(freq: float, duration: float) -> Dictionary:
	return {"freq": freq, "duration": duration}

func _setup_melodies() -> void:
	_melody = [
		_n(NOTE.E5, 0.5), _n(NOTE.B4, 0.5), _n(NOTE.C5, 0.5), _n(NOTE.D5, 0.5), _n(NOTE.C5, 0.5), _n(NOTE.B4, 0.5), _n(NOTE.A4, 1.5),
		_n(NOTE.A4, 0.5), _n(NOTE.C5, 0.5), _n(NOTE.E5, 0.5), _n(NOTE.D5, 0.5), _n(NOTE.C5, 0.5), _n(NOTE.B4, 0.5), _n(NOTE.B4, 1.5),
		_n(NOTE.C5, 0.5), _n(NOTE.D5, 0.5), _n(NOTE.E5, 1.0), _n(NOTE.C5, 1.0), _n(NOTE.A4, 1.0), _n(NOTE.A4, 1.0),
		_n(NOTE.D5, 1.0), _n(NOTE.F5, 0.5), _n(NOTE.A5, 0.5), _n(NOTE.G5, 0.5), _n(NOTE.F5, 0.5), _n(NOTE.E5, 1.0),
		_n(NOTE.C5, 0.5), _n(NOTE.E5, 0.5), _n(NOTE.D5, 0.5), _n(NOTE.C5, 0.5), _n(NOTE.B4, 1.0), _n(NOTE.B4, 0.5),
		_n(NOTE.C5, 0.5), _n(NOTE.D5, 1.0), _n(NOTE.E5, 1.0), _n(NOTE.C5, 1.0), _n(NOTE.A4, 1.0), _n(NOTE.A4, 1.0),
		_n(NOTE.E5, 0.5), _n(NOTE.B4, 0.5), _n(NOTE.C5, 0.5), _n(NOTE.D5, 0.5), _n(NOTE.C5, 0.5), _n(NOTE.B4, 0.5), _n(NOTE.A4, 1.5),
		_n(NOTE.A4, 0.5), _n(NOTE.C5, 0.5), _n(NOTE.E5, 0.5), _n(NOTE.D5, 0.5), _n(NOTE.C5, 0.5), _n(NOTE.B4, 0.5), _n(NOTE.B4, 1.5),
		_n(NOTE.C5, 0.5), _n(NOTE.D5, 0.5), _n(NOTE.E5, 1.0), _n(NOTE.C5, 1.0), _n(NOTE.A4, 1.0), _n(NOTE.A4, 1.0),
		_n(NOTE.D5, 1.0), _n(NOTE.F5, 0.5), _n(NOTE.A5, 0.5), _n(NOTE.G5, 0.5), _n(NOTE.F5, 0.5), _n(NOTE.E5, 1.0),
		_n(NOTE.C5, 0.5), _n(NOTE.E5, 0.5), _n(NOTE.D5, 0.5), _n(NOTE.C5, 0.5), _n(NOTE.B4, 1.0), _n(NOTE.B4, 0.5),
		_n(NOTE.C5, 0.5), _n(NOTE.D5, 1.0), _n(NOTE.E5, 1.0), _n(NOTE.C5, 1.0), _n(NOTE.A4, 1.0), _n(NOTE.G4, 2.0),
		_n(NOTE.A4, 1.0), _n(NOTE.B4, 1.0),
	]

	_jingle_bells_melody = [
		_n(NOTE.E5, 0.5), _n(NOTE.E5, 0.5), _n(NOTE.E5, 1.0), _n(NOTE.E5, 0.5), _n(NOTE.E5, 0.5), _n(NOTE.E5, 1.0),
		_n(NOTE.E5, 0.5), _n(NOTE.G5, 0.5), _n(NOTE.C5, 0.5), _n(NOTE.D5, 0.5), _n(NOTE.E5, 2.0),
		_n(NOTE.F5, 0.5), _n(NOTE.F5, 0.5), _n(NOTE.F5, 0.5), _n(NOTE.F5, 0.5), _n(NOTE.F5, 0.5),
		_n(NOTE.E5, 0.5), _n(NOTE.E5, 0.5), _n(NOTE.E5, 0.5), _n(NOTE.E5, 0.5), _n(NOTE.D5, 0.5),
		_n(NOTE.D5, 0.5), _n(NOTE.E5, 0.5), _n(NOTE.D5, 0.5), _n(NOTE.G5, 2.0),
		_n(NOTE.E5, 0.5), _n(NOTE.E5, 0.5), _n(NOTE.E5, 1.0), _n(NOTE.E5, 0.5), _n(NOTE.E5, 0.5), _n(NOTE.E5, 1.0),
		_n(NOTE.E5, 0.5), _n(NOTE.G5, 0.5), _n(NOTE.C5, 0.5), _n(NOTE.D5, 0.5), _n(NOTE.E5, 2.0),
		_n(NOTE.REST, 0.5), _n(NOTE.G5, 0.5), _n(NOTE.G5, 0.5), _n(NOTE.G5, 0.5), _n(NOTE.G5, 0.5), _n(NOTE.G5, 0.5),
		_n(NOTE.E5, 0.5), _n(NOTE.D5, 0.5), _n(NOTE.C5, 0.5), _n(NOTE.B4, 1.0), _n(NOTE.A4, 1.0), _n(NOTE.G4, 2.0),
	]
