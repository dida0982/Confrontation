class_name Scoreboard
extends PanelContainer
## Placar de abates que aparece segurando Tab: os dois times, cada jogador
## com abates e mortes, do melhor para o pior. A sua linha fica destacada.

const WIDTH := 600.0
const NAME_COLUMN_WIDTH := 340.0
const NUMBER_COLUMN_WIDTH := 110.0
const HEADER_COLOR := Color(0.65, 0.67, 0.72)
const HIGHLIGHT_COLOR := Color(1.0, 0.9, 0.4)

var match_mode: TeamDeathmatch
var local_player: Node

var _content: VBoxContainer
var _dirty := true


func _init(p_match: TeamDeathmatch, p_local_player: Node) -> void:
	match_mode = p_match
	local_player = p_local_player
	custom_minimum_size = Vector2(WIDTH, 0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.07, 0.1, 0.88)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(20)
	add_theme_stylebox_override("panel", style)

	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 6)
	add_child(_content)

	match_mode.stats_changed.connect(func() -> void: _dirty = true)


func _process(_delta: float) -> void:
	if visible and _dirty:
		_rebuild()


func _rebuild() -> void:
	_dirty = false
	for child in _content.get_children():
		child.queue_free()

	for team in [Team.Id.AZUL, Team.Id.VERMELHO]:
		var title := _label("TIME %s   %d" % [Team.name_of(team).to_upper(), match_mode.scores[team]], 24, Team.color_of(team))
		_content.add_child(title)

		var grid := GridContainer.new()
		grid.columns = 3
		grid.add_theme_constant_override("h_separation", 0)
		grid.add_theme_constant_override("v_separation", 4)
		_add_row(grid, "Jogador", "Abates", "Mortes", HEADER_COLOR, 16)
		for combatant in match_mode.ranking(team):
			var stats := match_mode.stats_of(combatant)
			var color := HIGHLIGHT_COLOR if combatant == local_player else Color.WHITE
			_add_row(grid, TeamDeathmatch.name_of(combatant), str(stats["kills"]), str(stats["deaths"]), color, 20)
		_content.add_child(grid)

		if team == Team.Id.AZUL:
			_content.add_child(HSeparator.new())


func _add_row(grid: GridContainer, player_name: String, kills: String, deaths: String, color: Color, font_size: int) -> void:
	var name_label := _label(player_name, font_size, color)
	name_label.custom_minimum_size = Vector2(NAME_COLUMN_WIDTH, 0)
	grid.add_child(name_label)
	for value in [kills, deaths]:
		var number := _label(value, font_size, color)
		number.custom_minimum_size = Vector2(NUMBER_COLUMN_WIDTH, 0)
		number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		grid.add_child(number)


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
