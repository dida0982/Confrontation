extends Control
## Menu principal: o mapa Porto em 3D ao fundo (câmera girando devagar) e, à
## esquerda, o título e os botões, no estilo do Valorant.
##
## Páginas: início (nome e botões), entrar (IP do host), sala (lobby com os
## times) e configurações (o mesmo painel do menu do Esc).

const COLUMN_WIDTH := 460.0
const TRAINING_ROOM := "res://scenes/sala_de_treino.tscn"
const BACKGROUND_MAP := "res://scenes/mapas/porto.tscn"
## Partes do mapa que não precisam existir no fundo do menu.
const BACKGROUND_SKIP := ["TeamDeathmatch", "HUD", "PauseMenu", "SpawnerJogadores", "Jogadores", "Bonecos", "Spawns"]
const ORBIT_RADIUS := 62.0
const ORBIT_HEIGHT := 34.0
const ORBIT_SPEED := 0.04
## Texto da tela de créditos (a lista completa fica em CREDITOS.md).
const CREDITS := """[b]CONFRONTATION[/b] usa só recursos gratuitos:

[b]Motor:[/b] Godot Engine (MIT)
[b]Fonte:[/b] Rajdhani, Indian Type Foundry (SIL Open Font License)
[b]Personagem e armas:[/b] Quaternius (CC0), via poly.pizza
[b]Texturas:[/b] Poly Haven (CC0): Dimitrios Savva, Rico Cilliers, Rob Tuytel
[b]Sons de tiro:[/b] "Gunshot Sounds" por Vincent Sevedge (CC-BY 3.0), via OpenGameArt
[b]Passos e impactos:[/b] Kenney, www.kenney.nl (CC0)
"""

var _start_page: VBoxContainer
var _join_page: VBoxContainer
var _lobby_page: VBoxContainer
var _settings_page: VBoxContainer
var _credits_page: VBoxContainer
var _column: VBoxContainer
var _name_edit: LineEdit
var _address_edit: LineEdit
var _message_label: Label
var _host_info_label: Label
var _team_lists := {}
var _team_buttons := {}
var _start_button: Button
var _settings: SettingsPanel
var _camera: Camera3D
var _orbit_angle := 0.6


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build()
	Rede.players_changed.connect(_refresh_lobby)
	Rede.joined_lobby.connect(func() -> void: _show_page(_lobby_page))
	_message_label.text = Rede.last_message
	_message_label.visible = not Rede.last_message.is_empty()
	Rede.last_message = ""
	# Voltando de uma partida em rede: continua na sala.
	_show_page(_lobby_page if Rede.is_online() else _start_page)


func _process(delta: float) -> void:
	# Câmera do fundo dando a volta no mapa.
	_orbit_angle += ORBIT_SPEED * delta
	_camera.position = Vector3(cos(_orbit_angle) * ORBIT_RADIUS, ORBIT_HEIGHT, sin(_orbit_angle) * ORBIT_RADIUS)
	_camera.look_at(Vector3(0, 0, -4))


func _show_page(page: Control) -> void:
	for each in [_start_page, _join_page, _lobby_page, _settings_page, _credits_page]:
		(each as Control).visible = each == page
	# As configurações precisam de mais espaço.
	_column.custom_minimum_size.x = SettingsPanel.WIDTH if page == _settings_page else COLUMN_WIDTH
	if page == _lobby_page:
		_refresh_lobby()
	if page == _settings_page:
		_settings.refresh()


# --- Ações dos botões --------------------------------------------------------

func _player_name() -> String:
	var player_name := Rede.clean_name(_name_edit.text)
	Configuracoes.set_player_name(player_name)
	return player_name


func _on_train_pressed(map_path: String) -> void:
	Rede.play_offline(_player_name(), map_path)


func _on_host_pressed() -> void:
	var error := Rede.host(_player_name())
	if error != OK:
		_show_message("Não foi possível criar a partida (a porta %d já está em uso?)." % Rede.PORT)


func _on_connect_pressed() -> void:
	var address := _address_edit.text.strip_edges()
	if address.is_empty():
		_show_message("Digite o IP do host.")
		return
	Configuracoes.set_last_address(address)
	var error := Rede.join(address, _player_name())
	if error != OK:
		_show_message("Não foi possível conectar nesse IP.")
		return
	_show_message("Conectando em %s..." % address)


func _show_message(text: String) -> void:
	_message_label.text = text
	_message_label.visible = not text.is_empty()


func _refresh_lobby() -> void:
	if not _lobby_page.visible:
		return
	var is_host := multiplayer.is_server()
	for team in _team_lists:
		var list := _team_lists[team] as Label
		var names := PackedStringArray()
		for id in Rede.players:
			var info: Dictionary = Rede.players[id]
			if info["team"] != team:
				continue
			var line: String = info["name"]
			if id == 1:
				line += "  (host)"
			if id == Rede.local_id():
				line += "  (você)"
			names.append(line)
		list.text = "\n".join(names) if not names.is_empty() else "(ninguém)"
		var button := _team_buttons[team] as Button
		var my_team: int = Rede.players.get(Rede.local_id(), {}).get("team", -1)
		button.disabled = my_team == team or Rede.team_count(team) >= Rede.MAX_PER_TEAM
	_start_button.visible = is_host
	if is_host:
		var addresses := Rede.local_addresses()
		_host_info_label.text = "Seus amigos entram com o IP: %s  (porta %d)" % [
			", ".join(addresses) if not addresses.is_empty() else "127.0.0.1", Rede.PORT]
	else:
		_host_info_label.text = "Esperando o host começar a partida..."


# --- Montagem da interface ---------------------------------------------------

func _build() -> void:
	_build_background()

	# Escurece o lado esquerdo para os botões ficarem fáceis de ler.
	var shade := TextureRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gradient := Gradient.new()
	gradient.set_color(0, Color(GameTheme.BACKGROUND, 0.97))
	gradient.set_color(1, Color(GameTheme.BACKGROUND, 0.15))
	gradient.add_point(0.45, Color(GameTheme.BACKGROUND, 0.85))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_to = Vector2(1, 0)
	shade.texture = texture
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(shade)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 80)
	margin.add_theme_constant_override("margin_top", 36)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	margin.add_child(scroll)

	_column = VBoxContainer.new()
	_column.custom_minimum_size = Vector2(COLUMN_WIDTH, 0)
	_column.add_theme_constant_override("separation", 8)
	scroll.add_child(_column)

	var title := _label("CONFRONTATION", 64)
	title.add_theme_font_override("font", GameTheme.bold_font())
	_column.add_child(title)
	var subtitle := _label("FPS TÁTICO  •  5 CONTRA 5  •  SEM HABILIDADES", 20)
	subtitle.add_theme_color_override("font_color", GameTheme.ACCENT)
	_column.add_child(subtitle)
	_column.add_child(_spacer(10))

	_message_label = _label("", 18)
	_message_label.add_theme_color_override("font_color", Color(1.0, 0.75, 0.4))
	_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_column.add_child(_message_label)

	_start_page = _page()
	_join_page = _page()
	_lobby_page = _page()
	_settings_page = _page()
	_credits_page = _page()
	_build_start_page()
	_build_join_page()
	_build_lobby_page()
	_build_settings_page()
	_build_credits_page()

	var footer := _label("versão %s  •  feito com Godot" % ProjectSettings.get_setting("application/config/version", "?"), 16)
	footer.add_theme_color_override("font_color", GameTheme.TEXT_DIM)
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 20)
	footer.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	footer.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(footer)


## O mapa Porto num "mundo" separado, só para enfeitar o fundo.
func _build_background() -> void:
	var container := SubViewportContainer.new()
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.stretch = true
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(container)

	var viewport := SubViewport.new()
	viewport.own_world_3d = true
	viewport.handle_input_locally = false
	container.add_child(viewport)

	var map := (load(BACKGROUND_MAP) as PackedScene).instantiate()
	for node_name in BACKGROUND_SKIP:
		var node := map.get_node_or_null(node_name)
		if node != null:
			map.remove_child(node)
			node.free()
	viewport.add_child(map)

	_camera = Camera3D.new()
	_camera.fov = 55
	viewport.add_child(_camera)
	_camera.make_current()


func _build_start_page() -> void:
	_start_page.add_child(_label("SEU NOME", 18))
	_name_edit = LineEdit.new()
	_name_edit.max_length = Rede.MAX_NAME_LENGTH
	_name_edit.placeholder_text = "Jogador"
	_name_edit.text = Configuracoes.player_name
	_name_edit.custom_minimum_size = Vector2(0, 42)
	_start_page.add_child(_name_edit)
	_start_page.add_child(_spacer(4))

	_start_page.add_child(_button("Criar partida", _on_host_pressed, true))
	_start_page.add_child(_button("Entrar em partida", func() -> void: _show_page(_join_page)))
	_start_page.add_child(_button("Treinar sozinho no Porto", func() -> void: _on_train_pressed(Rede.DEFAULT_MAP)))
	_start_page.add_child(_button("Sala de treino", func() -> void: _on_train_pressed(TRAINING_ROOM)))
	_start_page.add_child(_button("Configurações", func() -> void: _show_page(_settings_page)))
	_start_page.add_child(_button("Créditos", func() -> void: _show_page(_credits_page)))
	_start_page.add_child(_button("Sair do jogo", func() -> void: get_tree().quit()))


func _build_join_page() -> void:
	_join_page.add_child(_label("IP DO HOST (QUEM CRIOU A PARTIDA)", 18))
	_address_edit = LineEdit.new()
	_address_edit.text = Configuracoes.last_address
	_address_edit.custom_minimum_size = Vector2(0, 44)
	_address_edit.text_submitted.connect(func(_text: String) -> void: _on_connect_pressed())
	_join_page.add_child(_address_edit)
	_join_page.add_child(_button("Conectar", _on_connect_pressed, true))
	_join_page.add_child(_button("Voltar", func() -> void: _show_page(_start_page)))


func _build_lobby_page() -> void:
	var panel := PanelContainer.new()
	_lobby_page.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)

	var title := _label("SALA", 30)
	title.add_theme_font_override("font", GameTheme.bold_font())
	box.add_child(title)
	_host_info_label = _label("", 17)
	_host_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_host_info_label)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 16)
	for team in [Team.Id.AZUL, Team.Id.VERMELHO]:
		var column := VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var team_title := _label("TIME %s  (MÁX. %d)" % [Team.name_of(team).to_upper(), Rede.MAX_PER_TEAM], 20)
		team_title.add_theme_color_override("font_color", Team.color_of(team))
		column.add_child(team_title)
		var list := _label("", 19)
		list.custom_minimum_size = Vector2(0, 140)
		list.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		column.add_child(list)
		_team_lists[team] = list
		var chosen_team: Team.Id = team
		var button := _button("Entrar no %s" % Team.name_of(team), func() -> void: Rede.request_team(chosen_team))
		column.add_child(button)
		_team_buttons[team] = button
		columns.add_child(column)
	box.add_child(columns)

	_start_button = _button("Começar partida", func() -> void: Rede.start_match(Rede.DEFAULT_MAP), true)
	_lobby_page.add_child(_start_button)
	_lobby_page.add_child(_button("Sair da sala", func() -> void: Rede.leave()))


func _build_settings_page() -> void:
	var title := _label("CONFIGURAÇÕES", 30)
	title.add_theme_font_override("font", GameTheme.bold_font())
	_settings_page.add_child(title)
	_settings = SettingsPanel.new()
	_settings_page.add_child(_settings)
	_settings_page.add_child(_button("Voltar", func() -> void: _show_page(_start_page)))


func _build_credits_page() -> void:
	var panel := PanelContainer.new()
	_credits_page.add_child(panel)
	var text := RichTextLabel.new()
	text.bbcode_enabled = true
	text.fit_content = true
	text.text = CREDITS
	text.add_theme_font_size_override("normal_font_size", 18)
	text.add_theme_font_size_override("bold_font_size", 18)
	text.add_theme_font_override("bold_font", GameTheme.bold_font())
	panel.add_child(text)
	_credits_page.add_child(_button("Voltar", func() -> void: _show_page(_start_page)))


func _page() -> VBoxContainer:
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 8)
	_column.add_child(page)
	return page


func _spacer(height: float) -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, height)
	return spacer


func _label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	return label


## Botão do menu. "highlight" = botão principal da página (vermelho).
func _button(text: String, on_pressed: Callable, highlight: bool = false) -> Button:
	var button := Button.new()
	button.text = text.to_upper()
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(0, 44)
	button.add_theme_font_size_override("font_size", 22)
	button.focus_mode = Control.FOCUS_NONE
	if highlight:
		var style := StyleBoxFlat.new()
		style.bg_color = GameTheme.ACCENT
		style.set_corner_radius_all(2)
		style.content_margin_left = 14
		button.add_theme_stylebox_override("normal", style)
		button.add_theme_color_override("font_color", Color.WHITE)
	button.pressed.connect(on_pressed)
	return button
