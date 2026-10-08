extends CanvasLayer
## Interface na tela: mira, vida, munição, arma atual, marcador de acerto, luneta da sniper,
## placar e tempo da partida, feed de abates, tela de morte, tela de fim de partida
## o placar de abates (segurando Tab) e o minimapa no canto superior esquerdo.
## Tudo é criado por código aqui para ficar fácil de ajustar.
##
## Em rede, o jogador local só aparece quando todos carregaram o mapa. Até lá
## o HUD mostra "Esperando os outros jogadores..." e depois se liga a ele.

const HIT_MARKER_TIME := 0.15
const KILLFEED_TIME := 5.0
const KILLFEED_MAX := 5
const KILLFEED_WIDTH := 460.0

@export var match_path: NodePath
## Nó com as caixas do mapa (o minimapa é desenhado a partir delas).
@export var map_path: NodePath

var player: Player
var weapons: WeaponManager
var match_mode: TeamDeathmatch

var _root: Control
var _crosshair: Control
var _scope_overlay: Control
var _health_label: Label
var _ammo_label: Label
var _weapon_label: Label
var _info_label: Label
var _center_label: Label
var _voice_label: RichTextLabel
var _score_azul: Label
var _score_vermelho: Label
var _timer_label: Label
var _protection_label: Label
var _death_overlay: ColorRect
var _death_label: Label
var _end_title: Label
var _end_subtitle: Label
var _killfeed: RichTextLabel
var _scoreboard: Scoreboard
var _minimap: Minimap
## Cada item: {"text": String, "time": float}
var _killfeed_entries: Array[Dictionary] = []
var _hit_marker_timer := 0.0
var _hit_marker_color := Color.WHITE


func _ready() -> void:
	match_mode = get_node(match_path) as TeamDeathmatch
	match_mode.kill_registered.connect(_on_kill_registered)
	match_mode.local_player_spawned.connect(_bind_player)

	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_scope_overlay = _new_full_rect_control()
	_scope_overlay.draw.connect(_draw_scope)
	_crosshair = _new_full_rect_control()
	_crosshair.draw.connect(_draw_crosshair)

	_death_overlay = ColorRect.new()
	_death_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_death_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_death_overlay.color = Color(0.4, 0.0, 0.0, 0.3)
	_root.add_child(_death_overlay)

	_killfeed = RichTextLabel.new()
	_killfeed.bbcode_enabled = true
	_killfeed.fit_content = true
	_killfeed.scroll_active = false
	_killfeed.autowrap_mode = TextServer.AUTOWRAP_OFF
	_killfeed.custom_minimum_size = Vector2(KILLFEED_WIDTH, 0)
	_killfeed.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_killfeed.add_theme_font_size_override("normal_font_size", 18)
	_killfeed.add_theme_constant_override("outline_size", 5)
	_killfeed.add_theme_color_override("font_outline_color", Color.BLACK)
	_root.add_child(_killfeed)

	_score_azul = _new_label(36)
	_score_azul.add_theme_color_override("font_color", Team.color_of(Team.Id.AZUL))
	_score_vermelho = _new_label(36)
	_score_vermelho.add_theme_color_override("font_color", Team.color_of(Team.Id.VERMELHO))
	_timer_label = _new_label(28)
	_protection_label = _new_label(18)
	_protection_label.text = "PROTEÇÃO DE NASCIMENTO"
	_death_label = _new_label(32)
	_death_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_end_title = _new_label(72)
	_end_subtitle = _new_label(28)
	_end_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_health_label = _new_label(40)
	_ammo_label = _new_label(40)
	_weapon_label = _new_label(24)
	_info_label = _new_label(16)
	_center_label = _new_label(28)
	_center_label.text = "Esperando os outros jogadores..."

	_voice_label = RichTextLabel.new()
	_voice_label.bbcode_enabled = true
	_voice_label.fit_content = true
	_voice_label.scroll_active = false
	_voice_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_voice_label.custom_minimum_size = Vector2(420, 0)
	_voice_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_voice_label.add_theme_font_size_override("normal_font_size", 18)
	_voice_label.add_theme_constant_override("outline_size", 5)
	_voice_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_root.add_child(_voice_label)


## O jogador deste computador apareceu: liga o HUD a ele.
func _bind_player(local_player: Player) -> void:
	player = local_player
	weapons = player.weapons
	weapons.hit_confirmed.connect(_on_hit_confirmed)
	_center_label.text = "Clique para jogar"

	_minimap = Minimap.new(match_mode, player, get_node(map_path) as Node3D)
	_root.add_child(_minimap)

	_scoreboard = Scoreboard.new(match_mode, player)
	_scoreboard.visible = false
	_root.add_child(_scoreboard)


func _process(delta: float) -> void:
	if player != null and (not is_instance_valid(player) or not player.is_inside_tree()):
		player = null
		weapons = null
	if player == null:
		_center_label.visible = true
		_update_match_info()
		_layout()
		return

	_hit_marker_timer = maxf(_hit_marker_timer - delta, 0.0)

	_health_label.text = "VIDA  %d" % player.health.current
	_weapon_label.text = "[%d] %s" % [weapons.current_index + 1, weapons.current().display_name]
	if weapons.is_reloading():
		_ammo_label.text = "RECARREGANDO..."
	else:
		_ammo_label.text = "%d / ∞" % weapons.ammo_in_magazine()
	_info_label.text = "%s[1] Fuzil  [2] Pistola  [3] Sniper  |  R recarregar  |  Botão direito: zoom da sniper\nShift correr  |  Ctrl agachar  |  Espaço pular  |  Esc menu  |  Tab placar  |  V falar  |  F11 tela cheia%s" % [
		"FPS %d\n" % Engine.get_frames_per_second() if Configuracoes.show_fps else "",
		"  |  F8 morrer (teste)" if OS.is_debug_build() else ""]
	_center_label.visible = Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and not _is_menu_open()

	_update_match_info()
	_update_killfeed(delta)
	_update_voice()
	_scoreboard.visible = Input.is_action_pressed("scoreboard") and not _is_menu_open()

	_layout()
	_crosshair.queue_redraw()
	_scope_overlay.queue_redraw()


func _layout() -> void:
	var screen := _root.size
	var margin := 24.0
	for label in [_health_label, _ammo_label, _weapon_label, _info_label, _center_label, _score_azul,
			_score_vermelho, _timer_label, _protection_label, _death_label, _end_title, _end_subtitle]:
		(label as Label).reset_size()
	_health_label.position = Vector2(margin, screen.y - _health_label.size.y - margin)
	_ammo_label.position = Vector2(screen.x - _ammo_label.size.x - margin, screen.y - _ammo_label.size.y - margin)
	_weapon_label.position = Vector2(screen.x - _weapon_label.size.x - margin, _ammo_label.position.y - _weapon_label.size.y)
	if _minimap != null:
		_minimap.position = Vector2(16.0, 16.0)
	_info_label.position = Vector2(margin, _health_label.position.y - _info_label.size.y - 8.0)
	_voice_label.position = Vector2(margin, _info_label.position.y - _voice_label.size.y - 8.0)
	_center_label.position = (screen - _center_label.size) / 2.0 + Vector2(0, 60)

	# Placar no topo: "12   9:12   7"
	_timer_label.position = Vector2((screen.x - _timer_label.size.x) / 2.0, margin)
	_score_azul.position = Vector2(_timer_label.position.x - _score_azul.size.x - 24.0, margin - 4.0)
	_score_vermelho.position = Vector2(_timer_label.position.x + _timer_label.size.x + 24.0, margin - 4.0)

	_killfeed.position = Vector2(screen.x - KILLFEED_WIDTH - margin, margin)
	if _scoreboard != null:
		_scoreboard.reset_size()
		_scoreboard.position = Vector2((screen.x - _scoreboard.size.x) / 2.0, 80.0)
	_protection_label.position = Vector2((screen.x - _protection_label.size.x) / 2.0, screen.y / 2.0 + 40.0)
	_death_label.position = Vector2((screen.x - _death_label.size.x) / 2.0, screen.y * 0.3)
	_end_title.position = Vector2((screen.x - _end_title.size.x) / 2.0, screen.y * 0.3)
	_end_subtitle.position = Vector2((screen.x - _end_subtitle.size.x) / 2.0, _end_title.position.y + _end_title.size.y + 8.0)


func _update_match_info() -> void:
	_score_azul.text = str(match_mode.scores[Team.Id.AZUL])
	_score_vermelho.text = str(match_mode.scores[Team.Id.VERMELHO])
	var seconds := ceili(match_mode.time_left)
	_timer_label.text = "%d:%02d" % [floori(seconds / 60.0), seconds % 60]

	var ended := match_mode.state == TeamDeathmatch.State.ENDED
	if player == null:
		for node in [_death_overlay, _death_label, _protection_label, _end_title, _end_subtitle]:
			(node as CanvasItem).visible = false
		return
	var dead := player.health.is_dead
	_death_overlay.visible = dead and not ended
	_death_label.visible = dead and not ended
	if _death_label.visible:
		_death_label.text = "VOCÊ MORREU\nRenascendo em %.1f" % match_mode.respawn_time_left(player)
	_protection_label.visible = player.health.invulnerable and not dead

	_end_title.visible = ended
	_end_subtitle.visible = ended
	if ended:
		var my_team := player.health.team
		if match_mode.winner == -1:
			_end_title.text = "EMPATE"
			_end_title.add_theme_color_override("font_color", Color.WHITE)
		elif match_mode.winner == my_team:
			_end_title.text = "VITÓRIA"
			_end_title.add_theme_color_override("font_color", Team.color_of(my_team))
		else:
			_end_title.text = "DERROTA"
			_end_title.add_theme_color_override("font_color", Team.color_of(match_mode.winner as Team.Id))
		_end_subtitle.text = "Azul %d  x  %d Vermelho\n%s" % [
			match_mode.scores[Team.Id.AZUL], match_mode.scores[Team.Id.VERMELHO],
			"Aperte Enter para jogar de novo" if multiplayer.is_server() else "Esperando o host começar outra partida"]


## Chat de voz: mostra se você está transmitindo e quem está falando perto.
func _update_voice() -> void:
	var lines := PackedStringArray()
	if Voz.is_transmitting:
		lines.append("[color=#7dff9a]● Transmitindo sua voz[/color]")
	for id in Voz.speaking_ids():
		var speaker := match_mode.players_root.get_node_or_null(str(id))
		if speaker != null:
			lines.append("%s  falando" % _colored_name(speaker))
	_voice_label.text = "
".join(lines)


func _update_killfeed(delta: float) -> void:
	for entry in _killfeed_entries:
		entry["time"] -= delta
	_killfeed_entries = _killfeed_entries.filter(func(entry: Dictionary) -> bool: return entry["time"] > 0.0)
	var lines := PackedStringArray()
	for entry in _killfeed_entries:
		lines.append(entry["text"])
	_killfeed.text = "[right]%s[/right]" % "\n".join(lines)


func _on_kill_registered(killer: Node, victim: Node, headshot: bool) -> void:
	# O servidor confirmou que você matou: marcador vermelho.
	if player != null and killer == player:
		_hit_marker_timer = HIT_MARKER_TIME
		_hit_marker_color = Color.RED
	var victim_text := _colored_name(victim)
	var text: String
	if killer == null or killer == victim:
		text = "%s morreu" % victim_text
	else:
		text = "%s  matou  %s" % [_colored_name(killer), victim_text]
		if headshot:
			text += "  [color=#ffd84d](cabeça)[/color]"
	_killfeed_entries.append({"text": text, "time": KILLFEED_TIME})
	if _killfeed_entries.size() > KILLFEED_MAX:
		_killfeed_entries.pop_front()


func _colored_name(combatant: Node) -> String:
	var color := Team.color_of(TeamDeathmatch.team_of(combatant))
	return "[color=#%s]%s[/color]" % [color.to_html(false), TeamDeathmatch.name_of(combatant)]


func _draw_crosshair() -> void:
	if player == null:
		return
	var center := _crosshair.size / 2.0

	if _hit_marker_timer > 0.0:
		for dir in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
			_crosshair.draw_line(center + dir * 7.0, center + dir * 15.0, _hit_marker_color, 2.5)

	if weapons.is_scoped or player.health.is_dead:
		return

	Crosshair.draw(_crosshair, center)


func _draw_scope() -> void:
	if weapons == null or not weapons.is_scoped:
		return
	var screen := _scope_overlay.size
	var center := screen / 2.0
	var radius := minf(screen.x, screen.y) * 0.45
	var thickness := screen.length()
	# Pinta de preto tudo que está fora do círculo da luneta.
	_scope_overlay.draw_arc(center, radius + thickness / 2.0, 0.0, TAU, 128, Color.BLACK, thickness)
	_scope_overlay.draw_line(Vector2(center.x - radius, center.y), Vector2(center.x + radius, center.y), Color.BLACK, 1.5)
	_scope_overlay.draw_line(Vector2(center.x, center.y - radius), Vector2(center.x, center.y + radius), Color.BLACK, 1.5)
	_scope_overlay.draw_circle(center, 2.0, Color.RED)


func _is_menu_open() -> bool:
	var menu := get_tree().get_first_node_in_group("pause_menu")
	return menu != null and menu.is_open


func _on_hit_confirmed(headshot: bool, killed: bool) -> void:
	_hit_marker_timer = HIT_MARKER_TIME
	if killed:
		_hit_marker_color = Color.RED
	elif headshot:
		_hit_marker_color = Color.YELLOW
	else:
		_hit_marker_color = Color.WHITE


func _new_full_rect_control() -> Control:
	var control := Control.new()
	control.set_anchors_preset(Control.PRESET_FULL_RECT)
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(control)
	return control


func _new_label(font_size: int) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(label)
	return label
