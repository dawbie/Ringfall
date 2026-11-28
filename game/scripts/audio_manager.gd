extends Node
## Global audio coordinator for Ringfall.
## Manages SFX pooling, dynamic music + Shadow Veil filtering, and ambient loops.

const MUSIC_PATHS: Dictionary = {
	&"ruins_theme": "res://assets/audio/music/ruins_theme.wav",
	&"shadow_veil_drone": "res://assets/audio/music/shadow_veil_drone.wav",
}

const AMBIENT_PATHS: Dictionary = {
	&"campfire_crackle": "res://assets/audio/ambient/campfire_crackle.wav",
}

const SFX_PATHS: Dictionary = {
	&"sword_swing_light": "res://assets/audio/sfx/sword_swing_light.wav",
	&"sword_swing_heavy": "res://assets/audio/sfx/sword_swing_heavy.wav",
	&"sword_pogo": "res://assets/audio/sfx/sword_pogo.wav",
	&"hit_flesh": "res://assets/audio/sfx/hit_flesh.wav",
	&"hit_heavy": "res://assets/audio/sfx/hit_heavy.wav",
	&"pogo_bounce": "res://assets/audio/sfx/pogo_bounce.wav",
	&"dash": "res://assets/audio/sfx/dash.wav",
	&"perfect_dodge": "res://assets/audio/sfx/perfect_dodge.wav",
	&"jump": "res://assets/audio/sfx/jump.wav",
	&"land": "res://assets/audio/sfx/land.wav",
	&"footstep": "res://assets/audio/sfx/footstep.wav",
	&"player_hurt": "res://assets/audio/sfx/player_hurt.wav",
	&"player_death": "res://assets/audio/sfx/player_death.wav",
	&"snare_root": "res://assets/audio/sfx/snare_root.wav",
	&"ring_enter": "res://assets/audio/sfx/ring_enter.wav",
	&"ring_exit": "res://assets/audio/sfx/ring_exit.wav",
	&"sanity_low_pulse": "res://assets/audio/sfx/sanity_low_pulse.wav",
	&"enemy_windup": "res://assets/audio/sfx/enemy_windup.wav",
	&"enemy_attack": "res://assets/audio/sfx/enemy_attack.wav",
	&"enemy_death": "res://assets/audio/sfx/enemy_death.wav",
	&"crossbow_shoot": "res://assets/audio/sfx/crossbow_shoot.wav",
	&"snare_shoot": "res://assets/audio/sfx/snare_shoot.wav",
	&"projectile_impact": "res://assets/audio/sfx/projectile_impact.wav",
	&"nightmare_spawn": "res://assets/audio/sfx/nightmare_spawn.wav",
	&"nightmare_dissolve": "res://assets/audio/sfx/nightmare_dissolve.wav",
	&"coin_drop": "res://assets/audio/sfx/coin_drop.wav",
	&"coin_pickup": "res://assets/audio/sfx/coin_pickup.wav",
	&"campfire_rest": "res://assets/audio/sfx/campfire_rest.wav",
	&"shrine_light": "res://assets/audio/sfx/shrine_light.wav",
	&"shrine_shadow": "res://assets/audio/sfx/shrine_shadow.wav",
	&"gate_unlock": "res://assets/audio/sfx/gate_unlock.wav",
	&"gate_locked": "res://assets/audio/sfx/gate_locked.wav",
	&"dialogue_blip": "res://assets/audio/sfx/dialogue_blip.wav",
	&"ui_click": "res://assets/audio/sfx/ui_click.wav",
	&"victory_fanfare": "res://assets/audio/sfx/victory_fanfare.wav",
}

const SFX_POOL_SIZE: int = 16
const BASE_MUSIC_DB: float = -10.0
const SILENT_DB: float = -60.0

var _streams: Dictionary = {}
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_cursor: int = 0
var _last_played_msec: Dictionary = {}

var _music_player: AudioStreamPlayer = null
var _drone_player: AudioStreamPlayer = null
var _campfire_player: AudioStreamPlayer = null
var _music_lowpass: AudioEffectLowPassFilter = null
var _music_bus_index: int = -1

var _shadow_veil_active: bool = false
var _sanity_ratio: float = 1.0
var _player_dead: bool = false
var _level_completed: bool = false
var _campfire_distance: float = 9999.0
var _current_music_key: StringName = &""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_buses()
	_preload_streams()
	_setup_players()


func _process(delta: float) -> void:
	_update_dynamic_mix(delta)


func _setup_buses() -> void:
	_ensure_bus(&"Music", &"Master")
	_ensure_bus(&"Ambient", &"Master")
	_ensure_bus(&"SFX", &"Master")

	_music_bus_index = AudioServer.get_bus_index(&"Music")
	if _music_bus_index != -1:
		var has_lpf := false
		for i in range(AudioServer.get_bus_effect_count(_music_bus_index)):
			var eff := AudioServer.get_bus_effect(_music_bus_index, i)
			if eff is AudioEffectLowPassFilter:
				_music_lowpass = eff as AudioEffectLowPassFilter
				has_lpf = true
				break
		if not has_lpf:
			_music_lowpass = AudioEffectLowPassFilter.new()
			_music_lowpass.cutoff_hz = 20500.0
			_music_lowpass.resonance = 0.65
			AudioServer.add_bus_effect(_music_bus_index, _music_lowpass)


func _ensure_bus(bus_name: StringName, send_to: StringName) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	var idx := AudioServer.bus_count
	AudioServer.add_bus(idx)
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, send_to)


func _preload_streams() -> void:
	for key in SFX_PATHS:
		_load_stream(key, SFX_PATHS[key], false)
	for key in MUSIC_PATHS:
		_load_stream(key, MUSIC_PATHS[key], true)
	for key in AMBIENT_PATHS:
		_load_stream(key, AMBIENT_PATHS[key], true)


func _load_stream(key: StringName, path: String, enable_loop: bool) -> void:
	if not ResourceLoader.exists(path):
		return
	var stream := ResourceLoader.load(path) as AudioStream
	if stream == null:
		return
	if enable_loop and stream is AudioStreamWAV:
		var wav := (stream as AudioStreamWAV).duplicate() as AudioStreamWAV
		var bytes_per_sample := 2 if wav.format == AudioStreamWAV.FORMAT_16_BITS else 1
		var channels := 2 if wav.stereo else 1
		var frame_bytes := bytes_per_sample * channels
		if frame_bytes > 0 and wav.data.size() >= frame_bytes:
			wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
			wav.loop_begin = 0
			wav.loop_end = int(wav.data.size() / frame_bytes)
		stream = wav
	_streams[key] = stream


func _setup_players() -> void:
	for i in range(SFX_POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.bus = &"SFX"
		add_child(player)
		_sfx_pool.append(player)

	_music_player = AudioStreamPlayer.new()
	_music_player.bus = &"Music"
	_music_player.volume_db = BASE_MUSIC_DB
	_music_player.finished.connect(_on_music_finished)
	add_child(_music_player)

	_drone_player = AudioStreamPlayer.new()
	_drone_player.bus = &"Ambient"
	_drone_player.volume_db = SILENT_DB
	_drone_player.finished.connect(_on_drone_finished)
	add_child(_drone_player)

	_campfire_player = AudioStreamPlayer.new()
	_campfire_player.bus = &"Ambient"
	_campfire_player.volume_db = SILENT_DB
	_campfire_player.finished.connect(_on_campfire_finished)
	add_child(_campfire_player)


func start_level_audio(music_key: StringName = &"ruins_theme") -> void:
	_shadow_veil_active = false
	_sanity_ratio = 1.0
	_player_dead = false
	_level_completed = false
	_campfire_distance = 9999.0

	if _music_lowpass != null:
		_music_lowpass.cutoff_hz = 20500.0

	play_music(music_key)

	var drone_stream := _streams.get(&"shadow_veil_drone") as AudioStream
	if drone_stream != null:
		if _drone_player.stream != drone_stream:
			_drone_player.stream = drone_stream
		if not _drone_player.playing:
			_drone_player.volume_db = SILENT_DB
			_drone_player.play()

	var fire_stream := _streams.get(&"campfire_crackle") as AudioStream
	if fire_stream != null:
		if _campfire_player.stream != fire_stream:
			_campfire_player.stream = fire_stream
		if not _campfire_player.playing:
			_campfire_player.volume_db = SILENT_DB
			_campfire_player.play()


func play_music(track_key: StringName) -> void:
	var stream := _streams.get(track_key) as AudioStream
	if stream == null:
		return
	if _current_music_key == track_key and _music_player.playing:
		return
	_current_music_key = track_key
	_music_player.stream = stream
	_music_player.volume_db = BASE_MUSIC_DB
	_music_player.play()


func stop_music() -> void:
	_current_music_key = &""
	_music_player.stop()
	_drone_player.stop()
	_campfire_player.stop()


func play_sfx(
	key: StringName,
	volume_db: float = 0.0,
	pitch_min: float = 0.94,
	pitch_max: float = 1.06,
	min_interval: float = 0.035
) -> void:
	var stream := _streams.get(key) as AudioStream
	if stream == null or _sfx_pool.is_empty():
		return

	var now := Time.get_ticks_msec()
	var last_msec := int(_last_played_msec.get(key, -100000))
	if min_interval > 0.0 and float(now - last_msec) < min_interval * 1000.0:
		return
	_last_played_msec[key] = now

	var player := _acquire_sfx_player()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = randf_range(pitch_min, pitch_max) if pitch_max > pitch_min else pitch_min
	player.play()


func set_shadow_veil_active(active: bool) -> void:
	_shadow_veil_active = active


func set_sanity_ratio(ratio: float) -> void:
	_sanity_ratio = clampf(ratio, 0.0, 1.0)


func set_player_dead(dead: bool) -> void:
	_player_dead = dead


func set_level_completed(completed: bool) -> void:
	_level_completed = completed


func set_campfire_distance(distance: float) -> void:
	_campfire_distance = maxf(0.0, distance)


func _acquire_sfx_player() -> AudioStreamPlayer:
	for i in range(_sfx_pool.size()):
		var idx := (_sfx_cursor + i) % _sfx_pool.size()
		var candidate := _sfx_pool[idx]
		if not candidate.playing:
			_sfx_cursor = (idx + 1) % _sfx_pool.size()
			return candidate
	var fallback := _sfx_pool[_sfx_cursor]
	_sfx_cursor = (_sfx_cursor + 1) % _sfx_pool.size()
	return fallback


func _update_dynamic_mix(delta: float) -> void:
	var blend_rate := clampf(delta * 5.0, 0.0, 1.0)

	# Music volume & low-pass filtering under Shadow Veil / low Sanity / death
	var target_music_db := BASE_MUSIC_DB
	var target_cutoff := 20500.0

	if _player_dead or _level_completed:
		target_music_db = -26.0
		target_cutoff = 1200.0
	elif _shadow_veil_active:
		target_music_db = BASE_MUSIC_DB - 7.5
		target_cutoff = 720.0
	elif _sanity_ratio < 0.45:
		var madness := clampf((0.45 - _sanity_ratio) / 0.45, 0.0, 1.0)
		target_music_db = BASE_MUSIC_DB - 2.5 * madness
		target_cutoff = lerpf(12000.0, 2800.0, madness)

	if _music_player != null and _music_player.playing:
		_music_player.volume_db = lerpf(_music_player.volume_db, target_music_db, blend_rate)

	if _music_lowpass != null:
		_music_lowpass.cutoff_hz = lerpf(_music_lowpass.cutoff_hz, target_cutoff, blend_rate)

	# Shadow drone scales with Ring corruption and low Sanity
	var target_drone_db := SILENT_DB
	if not _player_dead and not _level_completed:
		var corruption_boost := clampf(float(GameState.ring_corruption) * 1.4, 0.0, 6.0)
		if _shadow_veil_active:
			target_drone_db = -12.0 + corruption_boost
		elif _sanity_ratio < 0.40:
			var madness := clampf((0.40 - _sanity_ratio) / 0.40, 0.0, 1.0)
			target_drone_db = lerpf(-34.0, -16.0 + corruption_boost * 0.5, madness)

	if _drone_player != null and _drone_player.playing:
		_drone_player.volume_db = lerpf(_drone_player.volume_db, target_drone_db, blend_rate)
		var target_pitch := 1.0 + clampf(float(GameState.ring_corruption) * 0.015, 0.0, 0.12)
		_drone_player.pitch_scale = lerpf(_drone_player.pitch_scale, target_pitch, blend_rate)

	# Campfire proximity crackle
	var target_fire_db := SILENT_DB
	if not _player_dead and not _level_completed and _campfire_distance < 260.0:
		var proximity := 1.0 - clampf(_campfire_distance / 260.0, 0.0, 1.0)
		target_fire_db = lerpf(-38.0, -13.0, proximity * proximity)
		if _shadow_veil_active:
			target_fire_db -= 10.0

	if _campfire_player != null and _campfire_player.playing:
		_campfire_player.volume_db = lerpf(_campfire_player.volume_db, target_fire_db, blend_rate)


func _on_music_finished() -> void:
	if _current_music_key != &"" and _music_player.stream != null:
		_music_player.play()


func _on_drone_finished() -> void:
	if _drone_player.stream != null:
		_drone_player.play()


func _on_campfire_finished() -> void:
	if _campfire_player.stream != null:
		_campfire_player.play()
