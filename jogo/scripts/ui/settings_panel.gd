class_name SettingsPanel
extends TabContainer
## Painel de configurações com abas: Mira, Vídeo, Áudio e Voz.
## É usado no menu principal e no menu do Esc. Cada mudança é salva na hora
## (Configuracoes.set_option) e o painel se redesenha com os valores novos.

const LABEL_WIDTH := 250.0
const WIDTH := 640.0

var _preview: Control
var _mic_meter: ProgressBar


func _init() -> void:
	custom_minimum_size = Vector2(WIDTH, 400)


func _ready() -> void:
	refresh()


func _process(_delta: float) -> void:
	if _mic_meter != null and is_visible_in_tree():
		_mic_meter.value = Voz.input_level


## Monta as abas de novo com os valores atuais.
func refresh() -> void:
	var tab := current_tab
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_build_crosshair_tab()
	_build_video_tab()
	_build_audio_tab()
	_build_voice_tab()
	current_tab = clampi(tab, 0, get_tab_count() - 1)


# --- Abas ---------------------------------------------------------------------

func _build_crosshair_tab() -> void:
	var tab := _tab("Mira")
	var settings := Configuracoes
	_slider_row(tab, "Sensibilidade do mouse", GameSettings.MIN_SENSITIVITY, GameSettings.MAX_SENSITIVITY, 0.01,
		settings.sensitivity, func(v: float) -> void: settings.set_sensitivity(v), "%.2f")
	_choice_row(tab, "Tipo de mira", ["Ponto", "Cruz"], settings.crosshair_style,
		func(i: int) -> void: _change("crosshair_style", i))
	var color_names := Crosshair.COLORS.keys()
	var color_index := 0
	for i in color_names.size():
		if Crosshair.COLORS[color_names[i]].is_equal_approx(settings.crosshair_color):
			color_index = i
	_choice_row(tab, "Cor", color_names, color_index,
		func(i: int) -> void: _change("crosshair_color", Crosshair.COLORS[color_names[i]]))
	_slider_row(tab, "Tamanho", 2, 20, 1, settings.crosshair_size,
		func(v: float) -> void: Configuracoes.set_option("crosshair_size", v), "%d")
	if settings.crosshair_style == GameSettings.CrosshairStyle.CRUZ:
		_slider_row(tab, "Espessura", 1, 6, 1, settings.crosshair_thickness,
			func(v: float) -> void: Configuracoes.set_option("crosshair_thickness", v), "%d")
		_slider_row(tab, "Espaço no meio", 0, 12, 1, settings.crosshair_gap,
			func(v: float) -> void: Configuracoes.set_option("crosshair_gap", v), "%d")
	_toggle_row(tab, "Contorno preto", settings.crosshair_outline,
		func(on: bool) -> void: _change("crosshair_outline", on))

	# Prévia: fundo cinza com a mira escolhida no meio.
	_preview = ColorRect.new()
	(_preview as ColorRect).color = Color(0.32, 0.34, 0.38)
	_preview.custom_minimum_size = Vector2(0, 90)
	_preview.draw.connect(func() -> void: Crosshair.draw(_preview, _preview.size / 2.0))
	tab.add_child(_preview)


func _build_video_tab() -> void:
	var tab := _tab("Vídeo")
	var settings := Configuracoes
	_choice_row(tab, "Modo de tela", ["Janela", "Tela cheia", "Tela cheia exclusiva"], settings.window_mode,
		func(i: int) -> void: _change("window_mode", i))
	if settings.window_mode == GameSettings.WindowMode.JANELA:
		var names := []
		var selected := 0
		for i in GameSettings.RESOLUTIONS.size():
			var res: Vector2i = GameSettings.RESOLUTIONS[i]
			names.append("%d x %d" % [res.x, res.y])
			if res == settings.resolution:
				selected = i
		_choice_row(tab, "Tamanho da janela", names, selected,
			func(i: int) -> void: _change("resolution", GameSettings.RESOLUTIONS[i]))
	_toggle_row(tab, "VSync (evita a imagem \"rasgar\")", settings.vsync,
		func(on: bool) -> void: _change("vsync", on))
	var fps_names := []
	for limit in GameSettings.FPS_LIMITS:
		fps_names.append("Sem limite" if limit == 0 else str(limit))
	_choice_row(tab, "Limite de FPS", fps_names, maxi(GameSettings.FPS_LIMITS.find(settings.max_fps), 0),
		func(i: int) -> void: _change("max_fps", GameSettings.FPS_LIMITS[i]))
	_slider_row(tab, "Qualidade da imagem 3D", 50, 100, 5, settings.render_scale * 100.0,
		func(v: float) -> void: Configuracoes.set_option("render_scale", v / 100.0), "%d%%")
	_choice_row(tab, "Sombras", ["Desligadas", "Baixas", "Altas"], settings.shadow_quality,
		func(i: int) -> void: _change("shadow_quality", i))
	_toggle_row(tab, "Mostrar FPS", settings.show_fps,
		func(on: bool) -> void: _change("show_fps", on))
	tab.add_child(_hint("Dica: com o computador mais fraco, desligue as sombras e baixe a qualidade da imagem 3D."))


func _build_audio_tab() -> void:
	var tab := _tab("Áudio")
	var settings := Configuracoes
	_slider_row(tab, "Volume geral", 0, 100, 1, settings.master_volume * 100.0,
		func(v: float) -> void: Configuracoes.set_option("master_volume", v / 100.0), "%d%%")
	_slider_row(tab, "Efeitos (tiros, passos)", 0, 100, 1, settings.effects_volume * 100.0,
		func(v: float) -> void: Configuracoes.set_option("effects_volume", v / 100.0), "%d%%")
	_slider_row(tab, "Vozes dos outros jogadores", 0, 200, 1, settings.voice_volume * 100.0,
		func(v: float) -> void: settings.set_voice_volume(v / 100.0), "%d%%")


func _build_voice_tab() -> void:
	var tab := _tab("Voz")
	var settings := Configuracoes
	_choice_row(tab, "Como falar", ["Segurar V", "Voz aberta"], settings.voice_mode,
		func(i: int) -> void: _change("voice_mode", i))
	var devices := AudioServer.get_input_device_list()
	var names := []
	for device in devices:
		names.append("Padrão do Windows" if device == "Default" else device)
	_choice_row(tab, "Microfone", names, maxi(devices.find(settings.microphone), 0),
		func(i: int) -> void: settings.set_microphone(devices[i]))
	if settings.voice_mode == GameSettings.VoiceMode.ABERTA:
		_slider_row(tab, "Volume mínimo para transmitir", 0, 25, 1, settings.voice_threshold * 100.0,
			func(v: float) -> void: settings.set_voice_threshold(v / 100.0), "%d")
	var meter_row := _row(tab, "Teste do microfone")
	_mic_meter = ProgressBar.new()
	_mic_meter.max_value = 1.0
	_mic_meter.show_percentage = false
	_mic_meter.custom_minimum_size = Vector2(0, 16)
	_mic_meter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mic_meter.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	meter_row.add_child(_mic_meter)
	tab.add_child(_hint("Fale para ver a barra mexer. O teste só funciona durante uma partida. Use fone de ouvido para não fazer eco."))


# --- Ajudantes ----------------------------------------------------------------

## Muda a configuração e redesenha (algumas opções mostram/escondem outras).
func _change(property: String, value: Variant) -> void:
	Configuracoes.set_option(property, value)
	refresh.call_deferred()


func _tab(title: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = title
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 12)
	scroll.add_child(box)
	return box


func _row(parent: Control, text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(LABEL_WIDTH, 0)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(label)
	parent.add_child(row)
	return row


## Linha com barra deslizante e o valor escrito ao lado.
## A barra salva a configuração sem remontar o painel (para não atrapalhar o arraste).
func _slider_row(parent: Control, text: String, min_value: float, max_value: float, step: float,
		value: float, on_changed: Callable, value_format: String) -> void:
	var row := _row(parent, text)
	var slider := HSlider.new()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step
	slider.value = value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(slider)
	var value_label := Label.new()
	value_label.custom_minimum_size = Vector2(64, 0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.text = value_format % value
	row.add_child(value_label)
	slider.value_changed.connect(func(v: float) -> void:
		value_label.text = value_format % v
		on_changed.call(v)
		if _preview != null:
			_preview.queue_redraw()
	)


func _choice_row(parent: Control, text: String, options: Array, selected: int, on_selected: Callable) -> void:
	var row := _row(parent, text)
	var choice := OptionButton.new()
	choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choice.focus_mode = Control.FOCUS_NONE
	for option in options:
		choice.add_item(str(option))
	choice.select(selected)
	choice.item_selected.connect(func(i: int) -> void: on_selected.call(i))
	row.add_child(choice)


func _toggle_row(parent: Control, text: String, value: bool, on_toggled: Callable) -> void:
	var row := _row(parent, text)
	var toggle := CheckButton.new()
	toggle.button_pressed = value
	toggle.focus_mode = Control.FOCUS_NONE
	toggle.toggled.connect(func(on: bool) -> void: on_toggled.call(on))
	row.add_child(toggle)


func _hint(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", GameTheme.TEXT_DIM)
	label.add_theme_font_size_override("font_size", 16)
	return label
