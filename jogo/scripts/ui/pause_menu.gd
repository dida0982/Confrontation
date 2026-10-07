extends CanvasLayer
## Menu que abre com Esc. O jogo NÃO pausa (como no Valorant, porque é online),
## mas o jogador para de andar e atirar enquanto o menu está aberto.
##
## Páginas:
## - principal: Continuar, Mira, Sair do jogo
## - mira: sensibilidade do mouse e tipo de mira (ponto ou cruz), com prévia

const PANEL_WIDTH := 460.0

var is_open := false

var _main_page: VBoxContainer
var _crosshair_page: VBoxContainer
var _sensitivity_slider: HSlider
var _sensitivity_box: SpinBox
var _style_buttons := {}
var _preview: Control


func _ready() -> void:
	layer = 10
	add_to_group("pause_menu")
	_build()
	_set_open(false)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if is_open and _crosshair_page.visible:
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
	_crosshair_page.visible = page == _crosshair_page
	_sync_controls()


func _sync_controls() -> void:
	_sensitivity_slider.set_value_no_signal(Configuracoes.sensitivity)
	_sensitivity_box.set_value_no_signal(Configuracoes.sensitivity)
	for style in _style_buttons:
		(_style_buttons[style] as Button).set_pressed_no_signal(style == Configuracoes.crosshair_style)
	_preview.queue_redraw()


func _on_sensitivity_changed(value: float) -> void:
	Configuracoes.set_sensitivity(value)
	_sync_controls()


func _on_style_selected(style: GameSettings.CrosshairStyle) -> void:
	Configuracoes.set_crosshair_style(style)
	_sync_controls()


# --- Montagem da interface -------------------------------------------------

func _build() -> void:
	var backdrop := ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0, 0, 0, 0.6)
	add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(PANEL_WIDTH, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.09, 0.12, 0.95)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(24)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 16)
	panel.add_child(content)
	content.add_child(_title("CONFRONTATION", 32))

	_main_page = _page(content)
	_crosshair_page = _page(content)

	_main_page.add_child(_button("Continuar", func() -> void: _set_open(false)))
	_main_page.add_child(_button("Mira", func() -> void: _show_page(_crosshair_page)))
	_main_page.add_child(_button("Sair do jogo", func() -> void: get_tree().quit()))
	_build_crosshair_page()


func _build_crosshair_page() -> void:
	_crosshair_page.add_child(_title("MIRA", 24))

	_crosshair_page.add_child(_label("Sensibilidade (mesma escala do Valorant)"))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_sensitivity_slider = HSlider.new()
	_sensitivity_slider.min_value = GameSettings.MIN_SENSITIVITY
	_sensitivity_slider.max_value = GameSettings.MAX_SENSITIVITY
	_sensitivity_slider.step = 0.01
	_sensitivity_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sensitivity_slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
	row.add_child(_sensitivity_slider)
	_sensitivity_box = SpinBox.new()
	_sensitivity_box.min_value = GameSettings.MIN_SENSITIVITY
	_sensitivity_box.max_value = GameSettings.MAX_SENSITIVITY
	_sensitivity_box.step = 0.01
	_sensitivity_box.custom_minimum_size = Vector2(110, 0)
	_sensitivity_box.value_changed.connect(_on_sensitivity_changed)
	row.add_child(_sensitivity_box)
	_crosshair_page.add_child(row)

	_crosshair_page.add_child(_label("Tipo de mira"))
	var styles := HBoxContainer.new()
	styles.add_theme_constant_override("separation", 12)
	var group := ButtonGroup.new()
	for entry in [[GameSettings.CrosshairStyle.PONTO, "Ponto"], [GameSettings.CrosshairStyle.CRUZ, "Cruz"]]:
		var style: GameSettings.CrosshairStyle = entry[0]
		var button := _button(entry[1], func() -> void: _on_style_selected(style))
		button.toggle_mode = true
		button.button_group = group
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		styles.add_child(button)
		_style_buttons[style] = button
	_crosshair_page.add_child(styles)

	# Prévia: um quadrado escuro com a mira escolhida no meio.
	_preview = ColorRect.new()
	(_preview as ColorRect).color = Color(0.25, 0.27, 0.3)
	_preview.custom_minimum_size = Vector2(0, 110)
	_preview.draw.connect(func() -> void:
		Crosshair.draw(_preview, _preview.size / 2.0, Configuracoes.crosshair_style)
	)
	_crosshair_page.add_child(_preview)

	_crosshair_page.add_child(_button("Voltar", func() -> void: _show_page(_main_page)))


func _page(parent: Control) -> VBoxContainer:
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 10)
	parent.add_child(page)
	return page


func _title(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	return label


func _label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 18)
	return label


func _button(text: String, on_pressed: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 44)
	button.add_theme_font_size_override("font_size", 20)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(on_pressed)
	return button
