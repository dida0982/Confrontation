class_name GameSettings
extends Node
## Configurações do jogador: mira, vídeo, áudio, voz, nome e último IP usado.
## Fica carregado o jogo todo como "Configuracoes" e salva tudo num arquivo
## no computador do jogador, para continuar igual na próxima vez que abrir.
##
## Para criar uma configuração nova: declare a variável, coloque na lista
## SAVED (seção e chave no arquivo) e, se ela muda algo na hora, aplique em
## _apply(). Para mudar o valor use set_option("nome_da_variavel", valor).

signal changed

enum CrosshairStyle { PONTO, CRUZ }
## APERTAR = só transmite segurando V. ABERTA = transmite sozinho quando você fala.
enum VoiceMode { APERTAR, ABERTA }
enum WindowMode { JANELA, TELA_CHEIA, TELA_CHEIA_EXCLUSIVA }
enum ShadowQuality { DESLIGADA, BAIXA, ALTA }

const FILE_PATH := "user://configuracoes.cfg"
## Mesma escala de sensibilidade do Valorant (graus por movimento do mouse).
## Assim dá para usar o mesmo número de sensibilidade que você usa lá.
const DEGREES_PER_COUNT := 0.07
const MIN_SENSITIVITY := 0.05
const MAX_SENSITIVITY := 5.0
const EFFECTS_BUS := "Efeitos"
const RESOLUTIONS := [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(2560, 1440)]
const FPS_LIMITS := [0, 30, 60, 120, 144, 165, 240]

## variável -> [seção, chave] no arquivo de configurações.
const SAVED := {
	"sensitivity": ["mouse", "sensibilidade"],
	"crosshair_style": ["mira", "tipo"],
	"crosshair_color": ["mira", "cor"],
	"crosshair_size": ["mira", "tamanho"],
	"crosshair_thickness": ["mira", "espessura"],
	"crosshair_gap": ["mira", "espaco"],
	"crosshair_outline": ["mira", "contorno"],
	"window_mode": ["video", "modo_de_tela"],
	"resolution": ["video", "resolucao"],
	"vsync": ["video", "vsync"],
	"max_fps": ["video", "limite_fps"],
	"render_scale": ["video", "escala_3d"],
	"shadow_quality": ["video", "sombras"],
	"show_fps": ["video", "mostrar_fps"],
	"master_volume": ["audio", "geral"],
	"effects_volume": ["audio", "efeitos"],
	"voice_mode": ["voz", "modo"],
	"voice_volume": ["voz", "volume"],
	"voice_threshold": ["voz", "sensibilidade"],
	"microphone": ["voz", "microfone"],
	"player_name": ["jogador", "nome"],
	"last_address": ["rede", "ultimo_ip"],
	"bot_difficulty": ["bots", "dificuldade"],
}

# Mouse e mira
var sensitivity := 2.0
var crosshair_style := CrosshairStyle.CRUZ
var crosshair_color := Color(0.35, 1.0, 0.65)
## Comprimento de cada risco da cruz (ou tamanho do ponto), em pixels.
var crosshair_size := 7.0
var crosshair_thickness := 2.0
## Espaço vazio no meio da cruz, em pixels.
var crosshair_gap := 4.0
var crosshair_outline := true
# Vídeo
var window_mode := WindowMode.JANELA
var resolution := Vector2i(1280, 720)
var vsync := true
## 0 = sem limite.
var max_fps := 0
## Escala da imagem 3D (1 = nítida, menor = mais leve e mais borrada).
var render_scale := 1.0
var shadow_quality := ShadowQuality.ALTA
var show_fps := true
# Áudio (1 = 100%)
var master_volume := 1.0
var effects_volume := 1.0
# Voz
var voice_mode := VoiceMode.APERTAR
## Volume das vozes dos outros (1 = normal, 2 = dobro).
var voice_volume := 1.0
## Voz aberta: volume mínimo do microfone para começar a transmitir.
var voice_threshold := 0.02
var microphone := "Default"
# Jogador e rede
var player_name := ""
var last_address := "127.0.0.1"
## Última dificuldade de bots escolhida (0 = Fácil, 1 = Normal, 2 = Difícil).
var bot_difficulty := 1


func _ready() -> void:
	if AudioServer.get_bus_index(EFFECTS_BUS) == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, EFFECTS_BUS)
	var file := ConfigFile.new()
	if file.load(FILE_PATH) == OK:
		for property in SAVED:
			var where: Array = SAVED[property]
			var value = file.get_value(where[0], where[1], get(property))
			if typeof(value) == typeof(get(property)):
				set(property, value)
	sensitivity = clampf(sensitivity, MIN_SENSITIVITY, MAX_SENSITIVITY)
	# Sombras dos mapas que forem abertos depois.
	get_tree().node_added.connect(func(node: Node) -> void:
		if node is DirectionalLight3D:
			_apply_shadows(node)
	)
	_apply(true)


## Muda uma configuração, salva e aplica.
func set_option(property: String, value: Variant) -> void:
	assert(SAVED.has(property), "Configuração desconhecida: " + property)
	set(property, value)
	_save()
	_apply(property in ["window_mode", "resolution"])


## Quanto a câmera gira (em radianos) para cada pixel que o mouse anda.
func radians_per_pixel() -> float:
	return deg_to_rad(DEGREES_PER_COUNT * sensitivity)


# Atalhos usados em vários lugares do jogo.
func set_sensitivity(value: float) -> void:
	set_option("sensitivity", clampf(value, MIN_SENSITIVITY, MAX_SENSITIVITY))


func set_crosshair_style(style: CrosshairStyle) -> void:
	set_option("crosshair_style", style)


func set_voice_mode(mode: VoiceMode) -> void:
	set_option("voice_mode", mode)


func set_voice_volume(value: float) -> void:
	set_option("voice_volume", clampf(value, 0.0, 2.0))


func set_voice_threshold(value: float) -> void:
	set_option("voice_threshold", clampf(value, 0.0, 0.25))


func set_microphone(device: String) -> void:
	set_option("microphone", device)


func set_player_name(value: String) -> void:
	set_option("player_name", value)


func set_last_address(value: String) -> void:
	set_option("last_address", value)


## Alterna entre janela e tela cheia (tecla F11).
func toggle_fullscreen() -> void:
	set_option("window_mode", WindowMode.JANELA if window_mode != WindowMode.JANELA else WindowMode.TELA_CHEIA)


# --- Aplicar ---------------------------------------------------------------

func _apply(apply_window: bool) -> void:
	if apply_window and DisplayServer.get_name() != "headless":
		_apply_window()
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = max_fps
	get_viewport().scaling_3d_scale = clampf(render_scale, 0.5, 1.0)
	RenderingServer.directional_shadow_atlas_set_size(4096 if shadow_quality == ShadowQuality.ALTA else 2048, true)
	for light in get_tree().root.find_children("*", "DirectionalLight3D", true, false):
		_apply_shadows(light)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(master_volume, 0.0001)))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(EFFECTS_BUS), linear_to_db(maxf(effects_volume, 0.0001)))


func _apply_window() -> void:
	var window := get_window()
	match window_mode:
		WindowMode.JANELA:
			window.mode = Window.MODE_WINDOWED
			window.size = resolution
			window.move_to_center()
		WindowMode.TELA_CHEIA:
			window.mode = Window.MODE_FULLSCREEN
		WindowMode.TELA_CHEIA_EXCLUSIVA:
			window.mode = Window.MODE_EXCLUSIVE_FULLSCREEN


func _apply_shadows(light: DirectionalLight3D) -> void:
	light.shadow_enabled = shadow_quality != ShadowQuality.DESLIGADA


func _save() -> void:
	var file := ConfigFile.new()
	for property in SAVED:
		var where: Array = SAVED[property]
		file.set_value(where[0], where[1], get(property))
	file.save(FILE_PATH)
	changed.emit()
