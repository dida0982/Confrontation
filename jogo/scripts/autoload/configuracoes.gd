class_name GameSettings
extends Node
## Configurações do jogador (sensibilidade, mira, voz, nome e último IP usado).
## Fica carregado o jogo todo como "Configuracoes" e salva tudo num arquivo
## no computador do jogador, para continuar igual na próxima vez que abrir.

signal changed

enum CrosshairStyle { PONTO, CRUZ }
## APERTAR = só transmite segurando V. ABERTA = transmite sozinho quando você fala.
enum VoiceMode { APERTAR, ABERTA }

const FILE_PATH := "user://configuracoes.cfg"
## Mesma escala de sensibilidade do Valorant (graus por movimento do mouse).
## Assim dá para usar o mesmo número de sensibilidade que você usa lá.
const DEGREES_PER_COUNT := 0.07
const MIN_SENSITIVITY := 0.05
const MAX_SENSITIVITY := 5.0

var sensitivity := 2.0
var crosshair_style := CrosshairStyle.CRUZ
var voice_mode := VoiceMode.APERTAR
## Volume das vozes dos outros (1 = normal, 2 = dobro).
var voice_volume := 1.0
## Voz aberta: volume mínimo do microfone para começar a transmitir.
var voice_threshold := 0.02
var microphone := "Default"
var player_name := ""
var last_address := "127.0.0.1"


func _ready() -> void:
	var file := ConfigFile.new()
	if file.load(FILE_PATH) == OK:
		sensitivity = clampf(file.get_value("mouse", "sensibilidade", sensitivity), MIN_SENSITIVITY, MAX_SENSITIVITY)
		crosshair_style = file.get_value("mira", "tipo", crosshair_style)
		voice_mode = file.get_value("voz", "modo", voice_mode)
		voice_volume = clampf(file.get_value("voz", "volume", voice_volume), 0.0, 2.0)
		voice_threshold = clampf(file.get_value("voz", "sensibilidade", voice_threshold), 0.0, 0.25)
		microphone = file.get_value("voz", "microfone", microphone)
		player_name = file.get_value("jogador", "nome", player_name)
		last_address = file.get_value("rede", "ultimo_ip", last_address)


## Quanto a câmera gira (em radianos) para cada pixel que o mouse anda.
func radians_per_pixel() -> float:
	return deg_to_rad(DEGREES_PER_COUNT * sensitivity)


func set_sensitivity(value: float) -> void:
	sensitivity = clampf(value, MIN_SENSITIVITY, MAX_SENSITIVITY)
	_save()


func set_crosshair_style(style: CrosshairStyle) -> void:
	crosshair_style = style
	_save()


func set_voice_mode(mode: VoiceMode) -> void:
	voice_mode = mode
	_save()


func set_voice_volume(value: float) -> void:
	voice_volume = clampf(value, 0.0, 2.0)
	_save()


func set_voice_threshold(value: float) -> void:
	voice_threshold = clampf(value, 0.0, 0.25)
	_save()


func set_microphone(device: String) -> void:
	microphone = device
	_save()


func set_player_name(value: String) -> void:
	player_name = value
	_save()


func set_last_address(value: String) -> void:
	last_address = value
	_save()


func _save() -> void:
	var file := ConfigFile.new()
	file.set_value("mouse", "sensibilidade", sensitivity)
	file.set_value("mira", "tipo", crosshair_style)
	file.set_value("voz", "modo", voice_mode)
	file.set_value("voz", "volume", voice_volume)
	file.set_value("voz", "sensibilidade", voice_threshold)
	file.set_value("voz", "microfone", microphone)
	file.set_value("jogador", "nome", player_name)
	file.set_value("rede", "ultimo_ip", last_address)
	file.save(FILE_PATH)
	changed.emit()
