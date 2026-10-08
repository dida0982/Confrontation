extends Node
## Voz: chat de voz por proximidade. Fica carregado o jogo todo como "Voz".
##
## Como funciona:
## 1. O microfone toca num bus de áudio mudo ("Microfone") que tem um
##    AudioEffectCapture. Daqui lemos o som gravado.
## 2. Enquanto você fala (segurando V, ou com voz aberta), o som é convertido
##    para mono, 16 kHz, e comprimido em μ-law (8 bits por amostra, como no
##    telefone). Pedaços de 40 ms são enviados ao servidor (host).
## 3. O servidor repassa só para quem está perto de quem falou (alcance + folga).
## 4. Quem recebe toca a voz no nó "Voz" (AudioStreamPlayer3D) do boneco de
##    quem falou: o volume cai com a distância e atrás de parede fica abafado.
##
## Quem está morto não fala; quem está morto continua ouvindo.

## Alcance da voz em metros (depois disso não se ouve nada).
const RANGE := 25.0
const SAMPLE_RATE := 16000
## Amostras por pacote (40 ms a 16 kHz).
const CHUNK_SAMPLES := 640
## Por quanto tempo alguém conta como "falando" depois do último pacote.
const SPEAKING_TIMEOUT := 0.35
## Voz aberta: continua transmitindo um pouco depois de parar de falar.
const VOICE_HANGOVER := 0.4
const OCCLUSION_INTERVAL := 0.2
const WORLD_MASK := 1
const MIC_BUS := "Microfone"
const VOICE_BUS := "Voz"
const MULAW_BIAS := 0x84
const MULAW_CLIP := 32635

## true enquanto este computador está transmitindo a sua voz.
var is_transmitting := false
## Volume atual do microfone (0 a 1), para o medidor no menu.
var input_level := 0.0

var _capture: AudioEffectCapture
var _mic_player: AudioStreamPlayer
var _resample_step := 1.0
var _resample_acc := 0.0
var _resample_count := 0
var _resample_pos := 0.0
var _chunk := PackedFloat32Array()
var _hangover := 0.0
var _decode_table := PackedFloat32Array()
var _exp_table := PackedInt32Array()
## id do jogador -> momento (s) do último pacote de voz recebido.
var _last_heard := {}
var _occlusion_timer := 0.0


func _ready() -> void:
	_build_tables()
	_setup_buses()
	_resample_step = AudioServer.get_mix_rate() / SAMPLE_RATE
	Configuracoes.changed.connect(_apply_settings)
	_apply_settings()


# --- Consultas ---------------------------------------------------------------

## true se o jogador com esse id falou há pouco (para mostrar quem está falando).
func is_speaking(player_id: int) -> bool:
	return _now() - _last_heard.get(player_id, -INF) < SPEAKING_TIMEOUT


## ids dos jogadores que estão falando agora (que você está ouvindo).
func speaking_ids() -> Array[int]:
	var ids: Array[int] = []
	for id in _last_heard:
		if is_speaking(id):
			ids.append(id)
	return ids


# --- Microfone e envio --------------------------------------------------------

func _process(delta: float) -> void:
	var player := _local_player()
	var mic_on := player != null
	if mic_on != _mic_player.playing:
		_mic_player.playing = mic_on
		_capture.clear_buffer()
	if not mic_on:
		is_transmitting = false
		input_level = 0.0
		return

	var frames := _capture.get_frames_available()
	var wants_push_to_talk := Input.is_action_pressed("push_to_talk") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	var open_mic := Configuracoes.voice_mode == GameSettings.VoiceMode.ABERTA
	var alive := not player.health.is_dead
	_hangover = maxf(_hangover - delta, 0.0)

	if frames > 0:
		_read_microphone(_capture.get_buffer(frames))

	while _chunk.size() >= CHUNK_SAMPLES:
		var samples := _chunk.slice(0, CHUNK_SAMPLES)
		_chunk = _chunk.slice(CHUNK_SAMPLES)
		var level := _rms(samples)
		input_level = clampf(level * 4.0, 0.0, 1.0)
		if open_mic and level >= Configuracoes.voice_threshold:
			_hangover = VOICE_HANGOVER
		is_transmitting = alive and (wants_push_to_talk or (open_mic and _hangover > 0.0))
		if is_transmitting:
			send_chunk(samples)

	_occlusion_timer -= delta
	if _occlusion_timer <= 0.0:
		_occlusion_timer = OCCLUSION_INTERVAL
		_update_occlusion(player)


## Comprime e envia 40 ms de voz (mono, 16 kHz, valores de -1 a 1).
## Também é usado pelos testes automáticos para mandar um som de teste.
func send_chunk(samples: PackedFloat32Array) -> void:
	var data := PackedByteArray()
	data.resize(samples.size())
	for i in samples.size():
		data[i] = _mulaw_encode(samples[i])
	_voice_from_client.rpc_id(1, data)


## Converte o som gravado (estéreo, 44,1/48 kHz) para mono 16 kHz.
func _read_microphone(frames: PackedVector2Array) -> void:
	for frame in frames:
		_resample_acc += (frame.x + frame.y) * 0.5
		_resample_count += 1
		_resample_pos += 1.0
		if _resample_pos >= _resample_step:
			_resample_pos -= _resample_step
			_chunk.append(_resample_acc / _resample_count)
			_resample_acc = 0.0
			_resample_count = 0


# --- Rede ----------------------------------------------------------------------

## Cliente -> servidor: um pedaço da minha voz.
@rpc("any_peer", "call_local", "unreliable_ordered", 1)
func _voice_from_client(data: PackedByteArray) -> void:
	if not multiplayer.is_server() or data.size() > CHUNK_SAMPLES * 2:
		return
	var speaker_id := multiplayer.get_remote_sender_id()
	if speaker_id == 0:
		speaker_id = multiplayer.get_unique_id()
	var speaker := _player_by_id(speaker_id)
	if speaker == null or speaker.health.is_dead:
		return
	for listener_id in Rede.players:
		if listener_id == speaker_id:
			continue
		var listener := _player_by_id(listener_id)
		if listener == null or listener.global_position.distance_to(speaker.global_position) > RANGE + 5.0:
			continue
		if listener_id == multiplayer.get_unique_id():
			_play(speaker_id, data)
		else:
			_voice_to_client.rpc_id(listener_id, speaker_id, data)


## Servidor -> cliente: voz de alguém que está perto.
@rpc("authority", "call_remote", "unreliable_ordered", 1)
func _voice_to_client(speaker_id: int, data: PackedByteArray) -> void:
	_play(speaker_id, data)


func _play(speaker_id: int, data: PackedByteArray) -> void:
	var speaker := _player_by_id(speaker_id)
	if speaker == null:
		return
	_last_heard[speaker_id] = _now()
	var voice := speaker.get_node("Voz") as AudioStreamPlayer3D
	if not voice.playing:
		voice.play()
	var playback := voice.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null or not playback.can_push_buffer(data.size()):
		return
	var frames := PackedVector2Array()
	frames.resize(data.size())
	for i in data.size():
		var sample := _decode_table[data[i]]
		frames[i] = Vector2(sample, sample)
	playback.push_buffer(frames)


# --- Paredes abafam a voz -------------------------------------------------------

func _update_occlusion(local_player: Player) -> void:
	var listener := local_player.camera.global_position
	var space := local_player.get_world_3d().direct_space_state
	for id in speaking_ids():
		var speaker := _player_by_id(id)
		if speaker == null:
			continue
		var voice := speaker.get_node("Voz") as AudioStreamPlayer3D
		var query := PhysicsRayQueryParameters3D.create(listener, voice.global_position, WORLD_MASK)
		var blocked := not space.intersect_ray(query).is_empty()
		voice.attenuation_filter_cutoff_hz = 900.0 if blocked else 20500.0
		voice.volume_db = -8.0 if blocked else 0.0


# --- Configurações e áudio -------------------------------------------------------

func _setup_buses() -> void:
	if AudioServer.get_bus_index(VOICE_BUS) == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, VOICE_BUS)
	if AudioServer.get_bus_index(MIC_BUS) == -1:
		AudioServer.add_bus()
		var index := AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, MIC_BUS)
		# Mudo: você não escuta a própria voz.
		AudioServer.set_bus_mute(index, true)
		_capture = AudioEffectCapture.new()
		_capture.buffer_length = 0.5
		AudioServer.add_bus_effect(index, _capture)
	_mic_player = AudioStreamPlayer.new()
	_mic_player.stream = AudioStreamMicrophone.new()
	_mic_player.bus = MIC_BUS
	add_child(_mic_player)


func _apply_settings() -> void:
	var bus := AudioServer.get_bus_index(VOICE_BUS)
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(Configuracoes.voice_volume, 0.0001)))
	var devices := AudioServer.get_input_device_list()
	var device := Configuracoes.microphone if devices.has(Configuracoes.microphone) else "Default"
	if AudioServer.input_device != device:
		AudioServer.input_device = device


# --- Ajudantes -------------------------------------------------------------------

func _local_player() -> Player:
	var match_mode := get_tree().get_first_node_in_group("match") as TeamDeathmatch
	if match_mode == null or not is_instance_valid(match_mode.local_player) or not match_mode.local_player.is_inside_tree():
		return null
	return match_mode.local_player


func _player_by_id(id: int) -> Player:
	var match_mode := get_tree().get_first_node_in_group("match") as TeamDeathmatch
	if match_mode == null:
		return null
	return match_mode.players_root.get_node_or_null(str(id)) as Player


static func _rms(samples: PackedFloat32Array) -> float:
	var total := 0.0
	for sample in samples:
		total += sample * sample
	return sqrt(total / maxf(samples.size(), 1))


static func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


func _build_tables() -> void:
	_exp_table.resize(256)
	for i in 256:
		_exp_table[i] = 0 if i < 2 else int(floor(log(float(i)) / log(2.0)))
	_decode_table.resize(256)
	for i in 256:
		var value := ~i & 0xFF
		var exponent := (value >> 4) & 0x07
		var mantissa := value & 0x0F
		var sample := (((mantissa << 3) + MULAW_BIAS) << exponent) - MULAW_BIAS
		if value & 0x80:
			sample = -sample
		_decode_table[i] = sample / 32768.0


## Comprime uma amostra (-1 a 1) em 1 byte (μ-law).
func _mulaw_encode(value: float) -> int:
	var sample := int(clampf(value, -1.0, 1.0) * 32767.0)
	var sign_bit := 0
	if sample < 0:
		sign_bit = 0x80
		sample = -sample
	sample = mini(sample, MULAW_CLIP) + MULAW_BIAS
	var exponent := _exp_table[(sample >> 7) & 0xFF]
	var mantissa := (sample >> (exponent + 3)) & 0x0F
	return ~(sign_bit | (exponent << 4) | mantissa) & 0xFF
