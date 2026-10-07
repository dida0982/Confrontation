extends Node
## Registra os controles do jogo (teclado e mouse) assim que o jogo abre.
## Para mudar uma tecla, troque aqui. Usamos a posição física da tecla,
## então funciona igual em teclado ABNT2 ou americano.

const TECLAS := {
	"move_forward": [KEY_W],
	"move_back": [KEY_S],
	"move_left": [KEY_A],
	"move_right": [KEY_D],
	"jump": [KEY_SPACE],
	"crouch": [KEY_CTRL, KEY_C],
	"sprint": [KEY_SHIFT],
	"reload": [KEY_R],
	"weapon_1": [KEY_1],
	"weapon_2": [KEY_2],
	"weapon_3": [KEY_3],
	"toggle_fullscreen": [KEY_F11],
}

const BOTOES_MOUSE := {
	"fire": [MOUSE_BUTTON_LEFT],
	"aim": [MOUSE_BUTTON_RIGHT],
	"weapon_prev": [MOUSE_BUTTON_WHEEL_UP],
	"weapon_next": [MOUSE_BUTTON_WHEEL_DOWN],
}


func _ready() -> void:
	for action in TECLAS:
		_criar_acao(action)
		for key in TECLAS[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)
	for action in BOTOES_MOUSE:
		_criar_acao(action)
		for button in BOTOES_MOUSE[action]:
			var event := InputEventMouseButton.new()
			event.button_index = button
			InputMap.action_add_event(action, event)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen"):
		var window := get_window()
		if window.mode == Window.MODE_FULLSCREEN:
			window.mode = Window.MODE_WINDOWED
		else:
			window.mode = Window.MODE_FULLSCREEN


func _criar_acao(action: String) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
