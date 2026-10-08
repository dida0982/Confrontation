extends CanvasLayer
## Menu que abre com Esc. O jogo NÃO pausa (como no Valorant, porque é online),
## mas o jogador para de andar e atirar enquanto o menu está aberto.
##
## Páginas:
## - principal: Continuar, Configurações, Voltar todos para a sala (só o host),
##   Sair da partida, Sair do jogo
## - configurações: abas Mira, Vídeo, Áudio e Voz (SettingsPanel)

const PANEL_WIDTH := 420.0

var is_open := false

var _main_page: Control
var _settings_page: Control
var _settings: SettingsPanel


func _ready() -> void:
	layer = 10
	add_to_group("pause_menu")
	_build()
	_set_open(false)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if is_open and _settings_page.visible:
		_show_page(_main_page)
	else:
		_set_open(not is_open)
	get_viewport().set_input_as_handled()


func _set_open(open: bool) -> void:
	is_open = open
	visible = open
	if open:
		_show_page(_main_page)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		var player := get_tree().get_first_node_in_group("player") as Player
		if player != null:
			player.weapons.block_fire_until_release()


func _show_page(page: Control) -> void:
	_main_page.visible = page == _main_page
	_settings_page.visible = page == _settings_page
	if page == _settings_page:
		_settings.refresh()


func _build() -> void:
	var backdrop := ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(GameTheme.BACKGROUND, 0.75)
	add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var panel := PanelContainer.new()
	center.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 16)
	panel.add_child(content)

	var title := Label.new()
	title.text = "CONFRONTATION"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", GameTheme.bold_font())
	title.add_theme_font_size_override("font_size", 40)
	content.add_child(title)

	var main_page := VBoxContainer.new()
	main_page.custom_minimum_size = Vector2(PANEL_WIDTH, 0)
	main_page.add_theme_constant_override("separation", 10)
	content.add_child(main_page)
	_main_page = main_page
	main_page.add_child(_button("Continuar", func() -> void: _set_open(false)))
	main_page.add_child(_button("Configurações", func() -> void: _show_page(_settings_page)))
	if Rede.is_online() and multiplayer.is_server():
		main_page.add_child(_button("Voltar todos para a sala", func() -> void: Rede.return_to_lobby()))
	main_page.add_child(_button("Sair da partida", func() -> void: Rede.leave()))
	main_page.add_child(_button("Sair do jogo", func() -> void: get_tree().quit()))

	var settings_page := VBoxContainer.new()
	settings_page.add_theme_constant_override("separation", 12)
	content.add_child(settings_page)
	_settings_page = settings_page
	_settings = SettingsPanel.new()
	settings_page.add_child(_settings)
	settings_page.add_child(_button("Voltar", func() -> void: _show_page(_main_page)))


func _button(text: String, on_pressed: Callable) -> Button:
	var button := Button.new()
	button.text = text.to_upper()
	button.custom_minimum_size = Vector2(0, 46)
	button.add_theme_font_size_override("font_size", 22)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(on_pressed)
	return button
