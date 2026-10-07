class_name GameSettings
extends Node
## Configurações do jogador (sensibilidade e mira).
## Fica carregado o jogo todo como "Configuracoes" e salva tudo num arquivo
## no computador do jogador, para continuar igual na próxima vez que abrir.

signal changed

enum CrosshairStyle { PONTO, CRUZ }

const FILE_PATH := "user://configuracoes.cfg"
## Mesma escala de sensibilidade do Valorant (graus por movimento do mouse).
## Assim dá para usar o mesmo número de sensibilidade que você usa lá.
const DEGREES_PER_COUNT := 0.07
const MIN_SENSITIVITY := 0.05
const MAX_SENSITIVITY := 5.0

var sensitivity := 2.0
var crosshair_style := CrosshairStyle.CRUZ


func _ready() -> void:
	var file := ConfigFile.new()
	if file.load(FILE_PATH) == OK:
		sensitivity = clampf(file.get_value("mouse", "sensibilidade", sensitivity), MIN_SENSITIVITY, MAX_SENSITIVITY)
		crosshair_style = file.get_value("mira", "tipo", crosshair_style)


## Quanto a câmera gira (em radianos) para cada pixel que o mouse anda.
func radians_per_pixel() -> float:
	return deg_to_rad(DEGREES_PER_COUNT * sensitivity)


func set_sensitivity(value: float) -> void:
	sensitivity = clampf(value, MIN_SENSITIVITY, MAX_SENSITIVITY)
	_save()


func set_crosshair_style(style: CrosshairStyle) -> void:
	crosshair_style = style
	_save()


func _save() -> void:
	var file := ConfigFile.new()
	file.set_value("mouse", "sensibilidade", sensitivity)
	file.set_value("mira", "tipo", crosshair_style)
	file.save(FILE_PATH)
	changed.emit()
