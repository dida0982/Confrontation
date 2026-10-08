class_name KillAnnouncer
extends Control
## Anúncios na tela quando VOCÊ mata (no estilo do Combat Arms): texto grande
## que "estoura" na tela, clarão colorido, raios saindo do centro, musiquinha e,
## nos maiores, a voz do locutor e a tela tremendo.
##
## - HEADSHOT!           abate com tiro na cabeça
## - DOUBLE / TRIPLE / QUADRA KILL, ACE!   abates seguidos, cada um até
##   MULTI_KILL_WINDOW segundos depois do anterior
## - EM CHAMAS! (3), IMPARÁVEL! (5), DOMINANDO! (7), LENDÁRIO! (10+)
##   abates em sequência sem morrer

## Pede para a câmera tremer (força de 0 a 1).
signal shake_requested(strength: float)

## Segundos entre um abate e outro para contar como abate múltiplo.
const MULTI_KILL_WINDOW := 4.0
const SHOW_TIME := 1.9
const RAY_COUNT := 18

const MULTI_KILLS := {
	2: {"title": "DOUBLE KILL!", "color": Color(1.0, 0.65, 0.2), "sound": "res://sons/anuncio_double.wav", "voice": "res://sons/voz_combo.ogg", "shake": 0.2},
	3: {"title": "TRIPLE KILL!", "color": Color(1.0, 0.35, 0.2), "sound": "res://sons/anuncio_triple.wav", "voice": "res://sons/voz_multi_kill.ogg", "shake": 0.45},
	4: {"title": "QUADRA KILL!", "color": Color(1.0, 0.25, 0.75), "sound": "res://sons/anuncio_multi.wav", "voice": "res://sons/voz_multi_kill.ogg", "shake": 0.7},
	5: {"title": "ACE!", "color": Color(1.0, 0.85, 0.2), "sound": "res://sons/anuncio_multi.wav", "voice": "res://sons/voz_flawless_victory.ogg", "shake": 1.0},
}
const STREAKS := {
	3: {"title": "EM CHAMAS!", "color": Color(1.0, 0.5, 0.15)},
	5: {"title": "IMPARÁVEL!", "color": Color(0.4, 0.8, 1.0)},
	7: {"title": "DOMINANDO!", "color": Color(0.75, 0.45, 1.0)},
	10: {"title": "LENDÁRIO!", "color": Color(1.0, 0.85, 0.2)},
}
const HEADSHOT := {"title": "HEADSHOT!", "color": Color(1.0, 0.9, 0.35), "sound": "res://sons/anuncio_headshot.wav", "shake": 0.0}
const STREAK_SOUND := "res://sons/anuncio_sequencia.wav"

var _multi := 0
var _streak := 0
var _last_kill_time := -INF
var _time_left := 0.0
var _age := 0.0
var _color := Color.WHITE
var _rainbow := false

var _banner: Control
var _title: Label
var _subtitle: Label
var _flash: ColorRect
var _jingle: AudioStreamPlayer
var _voice: AudioStreamPlayer


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	_flash = ColorRect.new()
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.color = Color(1, 1, 1, 0)
	add_child(_flash)

	_banner = Control.new()
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_banner)
	_title = _new_label(86)
	_subtitle = _new_label(30)
	_banner.add_child(_title)
	_banner.add_child(_subtitle)
	_banner.visible = false

	_jingle = _new_player(-6.0)
	_voice = _new_player(-2.0)


## Chame quando o jogador local matar alguém.
func register_kill(headshot: bool) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	_multi = _multi + 1 if now - _last_kill_time <= MULTI_KILL_WINDOW else 1
	_last_kill_time = now
	_streak += 1

	var streak_info: Dictionary = STREAKS.get(_streak, {})
	if _streak > 10 and _streak % 5 == 0:
		streak_info = {"title": "LENDÁRIO x%d!" % _streak, "color": Color(1.0, 0.85, 0.2)}

	if _multi >= 2:
		var info: Dictionary = MULTI_KILLS[mini(_multi, 5)]
		var subtitle: String = streak_info.get("title", "HEADSHOT" if headshot else "")
		_show(info["title"], subtitle, info["color"], info["sound"], info["voice"], info["shake"], _multi >= 5)
	elif not streak_info.is_empty():
		_show(streak_info["title"], "%d ABATES SEGUIDOS" % _streak, streak_info["color"], STREAK_SOUND, "", 0.35, _streak >= 10)
	elif headshot:
		_show(HEADSHOT["title"], "", HEADSHOT["color"], HEADSHOT["sound"], "", 0.0, false)


## Anúncio avulso (ex.: "FIGHT!" no começo da partida). Caminhos vazios = sem som.
func announce(title: String, subtitle: String, color: Color, sound: String, voice: String) -> void:
	_show(title, subtitle, color, sound, voice, 0.0, false)


## Chame quando o jogador local morrer: a sequência zera.
func reset_streak() -> void:
	_streak = 0
	_multi = 0


func _show(title: String, subtitle: String, color: Color, sound: String, voice: String, shake: float, rainbow: bool) -> void:
	_title.text = title
	_subtitle.text = subtitle
	_subtitle.visible = not subtitle.is_empty()
	_color = color
	_rainbow = rainbow
	_time_left = SHOW_TIME
	_age = 0.0
	_banner.visible = true
	_flash.color = Color(color, 0.22)
	if not sound.is_empty():
		_play(_jingle, sound)
	if not voice.is_empty():
		get_tree().create_timer(0.15).timeout.connect(func() -> void: _play(_voice, voice))
	if shake > 0.0:
		shake_requested.emit(shake)


func _process(delta: float) -> void:
	_flash.color.a = move_toward(_flash.color.a, 0.0, delta * 0.9)
	if _time_left <= 0.0:
		_banner.visible = false
		return
	_time_left -= delta
	_age += delta

	var color := _color
	if _rainbow:
		color = Color.from_hsv(fmod(_age * 0.8, 1.0), 0.65, 1.0)
	_title.add_theme_color_override("font_color", color)

	# Texto: entra grande e girado e "estoura" para o tamanho normal; no fim some crescendo.
	_title.reset_size()
	_subtitle.reset_size()
	var width := maxf(_title.size.x, _subtitle.size.x)
	_title.position = Vector2((width - _title.size.x) / 2.0, 0)
	_subtitle.position = Vector2((width - _subtitle.size.x) / 2.0, _title.size.y - 6.0)
	_banner.size = Vector2(width, _title.size.y + _subtitle.size.y)
	_banner.pivot_offset = _banner.size / 2.0
	_banner.position = Vector2((size.x - _banner.size.x) / 2.0, size.y * 0.2)

	var pop := clampf(_age / 0.3, 0.0, 1.0)
	var grow := 1.0 + 1.6 * pow(1.0 - pop, 3.0) - 0.12 * sin(pop * PI)
	var fade_out := clampf(_time_left / 0.35, 0.0, 1.0)
	_banner.scale = Vector2.ONE * grow * (1.0 + (1.0 - fade_out) * 0.25)
	_banner.rotation = deg_to_rad(-10.0) * pow(1.0 - pop, 2.0) + deg_to_rad(1.5) * sin(_age * 9.0) * fade_out
	_banner.modulate.a = minf(_age / 0.08, 1.0) * fade_out
	queue_redraw()


func _draw() -> void:
	if _time_left <= 0.0:
		return
	# Raios saindo de trás do texto, girando devagar e sumindo.
	var center := _banner.position + _banner.size / 2.0
	var progress := clampf(_age / 0.6, 0.0, 1.0)
	var alpha := (1.0 - progress) * 0.55 * _banner.modulate.a
	if alpha <= 0.01:
		return
	var color := Color(_title.get_theme_color("font_color"), alpha)
	for i in RAY_COUNT:
		var angle := TAU * i / RAY_COUNT + _age * 0.6
		var direction := Vector2(cos(angle), sin(angle) * 0.6)
		var start := center + direction * (60.0 + 220.0 * progress)
		var end := center + direction * (160.0 + 420.0 * progress)
		draw_line(start, end, color, 4.0 * (1.0 - progress) + 1.0)


func _play(player: AudioStreamPlayer, path: String) -> void:
	player.stream = load(path)
	player.play()


func _new_label(font_size: int) -> Label:
	var label := Label.new()
	label.add_theme_font_override("font", GameTheme.bold_font())
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_constant_override("outline_size", 14)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _new_player(volume_db: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = GameSettings.EFFECTS_BUS
	player.volume_db = volume_db
	add_child(player)
	return player
