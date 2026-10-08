extends Control
## Menu principal: nome do jogador, treinar sozinho, criar partida, entrar pelo
## IP e a SALA (lobby) onde cada um escolhe o time antes do host começar.

const PANEL_WIDTH := 560.0
const TRAINING_ROOM := "res://scenes/sala_de_treino.tscn"

var _start_page: VBoxContainer
var _join_page: VBoxContainer
var _lobby_page: VBoxContainer
var _name_edit: LineEdit
var _address_edit: LineEdit
var _message_label: Label
var _host_info_label: Label
var _team_lists := {}
var _team_buttons := {}
var _start_button: Button


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build()
	Rede.players_changed.connect(_refresh_lobby)
	Rede.joined_lobby.connect(func() -> void: _show_page(_lobby_page))
	_message_label.text = Rede.last_message
	Rede.last_message = ""
	# Voltando de uma partida em rede: continua na sala.
	_show_page(_lobby_page if Rede.is_online() else _start_page)


func _show_page(page: Control) -> void:
	for each in [_start_page, _join_page, _lobby_page]:
		(each as Control).visible = each == page
	if page == _lobby_page:
		_refresh_lobby()


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
		_message_label.text = "Não foi possível criar a partida (a porta %d já está em uso?)." % Rede.PORT


func _on_connect_pressed() -> void:
	var address := _address_edit.text.strip_edges()
	if address.is_empty():
		_message_label.text = "Digite o IP do host."
		return
	Configuracoes.set_last_address(address)
	var error := Rede.join(address, _player_name())
	if error != OK:
		_message_label.text = "Não foi possível conectar nesse IP."
		return
	_message_label.text = "Conectando em %s..." % address


func _on_leave_lobby_pressed() -> void:
	Rede.leave()


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
	var background := ColorRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.07, 0.08, 0.11)
	add_child(background)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(PANEL_WIDTH, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.13, 0.17)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(28)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	panel.add_child(content)
	content.add_child(_title("CONFRONTATION", 40))
	_message_label = _label("", 16)
	_message_label.add_theme_color_override("font_color", Color(1.0, 0.75, 0.4))
	_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_message_label)

	_start_page = _page(content)
	_join_page = _page(content)
	_lobby_page = _page(content)
	_build_start_page()
	_build_join_page()
	_build_lobby_page()


func _build_start_page() -> void:
	_start_page.add_child(_label("Seu nome", 18))
	_name_edit = LineEdit.new()
	_name_edit.max_length = Rede.MAX_NAME_LENGTH
	_name_edit.placeholder_text = "Jogador"
	_name_edit.text = Configuracoes.player_name
	_name_edit.custom_minimum_size = Vector2(0, 40)
	_start_page.add_child(_name_edit)

	_start_page.add_child(_button("Criar partida", _on_host_pressed))
	_start_page.add_child(_button("Entrar em partida", func() -> void: _show_page(_join_page)))
	_start_page.add_child(_button("Treinar sozinho no Porto", func() -> void: _on_train_pressed(Rede.DEFAULT_MAP)))
	_start_page.add_child(_button("Sala de treino", func() -> void: _on_train_pressed(TRAINING_ROOM)))
	_start_page.add_child(_button("Sair do jogo", func() -> void: get_tree().quit()))


func _build_join_page() -> void:
	_join_page.add_child(_label("IP do host (quem criou a partida)", 18))
	_address_edit = LineEdit.new()
	_address_edit.text = Configuracoes.last_address
	_address_edit.custom_minimum_size = Vector2(0, 40)
	_address_edit.text_submitted.connect(func(_text: String) -> void: _on_connect_pressed())
	_join_page.add_child(_address_edit)
	_join_page.add_child(_button("Conectar", _on_connect_pressed))
	_join_page.add_child(_button("Voltar", func() -> void: _show_page(_start_page)))


func _build_lobby_page() -> void:
	_lobby_page.add_child(_title("SALA", 26))
	_host_info_label = _label("", 16)
	_host_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lobby_page.add_child(_host_info_label)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 16)
	for team in [Team.Id.AZUL, Team.Id.VERMELHO]:
		var column := VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var title := _label("TIME %s (máx. %d)" % [Team.name_of(team).to_upper(), Rede.MAX_PER_TEAM], 20)
		title.add_theme_color_override("font_color", Team.color_of(team))
		column.add_child(title)
		var list := _label("", 18)
		list.custom_minimum_size = Vector2(0, 140)
		list.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		column.add_child(list)
		_team_lists[team] = list
		var chosen_team: Team.Id = team
		var button := _button("Entrar no %s" % Team.name_of(team), func() -> void: Rede.request_team(chosen_team))
		column.add_child(button)
		_team_buttons[team] = button
		columns.add_child(column)
	_lobby_page.add_child(columns)

	_start_button = _button("Começar partida", func() -> void: Rede.start_match(Rede.DEFAULT_MAP))
	_lobby_page.add_child(_start_button)
	_lobby_page.add_child(_button("Sair da sala", _on_leave_lobby_pressed))


func _page(parent: Control) -> VBoxContainer:
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 10)
	parent.add_child(page)
	return page


func _title(text: String, font_size: int) -> Label:
	var label := _label(text, font_size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


func _label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	return label


func _button(text: String, on_pressed: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 44)
	button.add_theme_font_size_override("font_size", 20)
	button.pressed.connect(on_pressed)
	return button
