extends CanvasLayer
## Interface na tela: mira, vida, munição, arma atual, marcador de acerto e luneta da sniper.
## Tudo é criado por código aqui para ficar fácil de ajustar.

const CROSSHAIR_COLOR := Color(0.35, 1.0, 0.65)
const CROSSHAIR_LENGTH := 6.0
const CROSSHAIR_THICKNESS := 2.0
const HIT_MARKER_TIME := 0.15

@export var player_path: NodePath

var player: Player
var weapons: WeaponManager

var _root: Control
var _crosshair: Control
var _scope_overlay: Control
var _health_label: Label
var _ammo_label: Label
var _weapon_label: Label
var _info_label: Label
var _center_label: Label
var _hit_marker_timer := 0.0
var _hit_marker_color := Color.WHITE


func _ready() -> void:
	player = get_node(player_path) as Player
	weapons = player.weapons
	weapons.hit_confirmed.connect(_on_hit_confirmed)

	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_scope_overlay = _new_full_rect_control()
	_scope_overlay.draw.connect(_draw_scope)
	_crosshair = _new_full_rect_control()
	_crosshair.draw.connect(_draw_crosshair)

	_health_label = _new_label(40)
	_ammo_label = _new_label(40)
	_weapon_label = _new_label(24)
	_info_label = _new_label(16)
	_center_label = _new_label(28)
	_center_label.text = "Clique para jogar"


func _process(delta: float) -> void:
	_hit_marker_timer = maxf(_hit_marker_timer - delta, 0.0)

	_health_label.text = "VIDA  %d" % player.health.current
	_weapon_label.text = "[%d] %s" % [weapons.current_index + 1, weapons.current().display_name]
	if weapons.is_reloading():
		_ammo_label.text = "RECARREGANDO..."
	else:
		_ammo_label.text = "%d / ∞" % weapons.ammo_in_magazine()
	_info_label.text = "FPS %d\n[1] Fuzil  [2] Pistola  [3] Sniper  |  R recarregar  |  Botão direito: zoom da sniper\nShift correr  |  Ctrl agachar  |  Espaço pular  |  Esc soltar o mouse  |  F11 tela cheia" % Engine.get_frames_per_second()
	_center_label.visible = Input.mouse_mode != Input.MOUSE_MODE_CAPTURED

	_layout()
	_crosshair.queue_redraw()
	_scope_overlay.queue_redraw()


func _layout() -> void:
	var screen := _root.size
	var margin := 24.0
	for label in [_health_label, _ammo_label, _weapon_label, _info_label, _center_label]:
		(label as Label).reset_size()
	_health_label.position = Vector2(margin, screen.y - _health_label.size.y - margin)
	_ammo_label.position = Vector2(screen.x - _ammo_label.size.x - margin, screen.y - _ammo_label.size.y - margin)
	_weapon_label.position = Vector2(screen.x - _weapon_label.size.x - margin, _ammo_label.position.y - _weapon_label.size.y)
	_info_label.position = Vector2(margin, margin)
	_center_label.position = (screen - _center_label.size) / 2.0 + Vector2(0, 60)


func _draw_crosshair() -> void:
	var center := _crosshair.size / 2.0

	if _hit_marker_timer > 0.0:
		for dir in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
			_crosshair.draw_line(center + dir * 7.0, center + dir * 15.0, _hit_marker_color, 2.5)

	if weapons.is_scoped:
		return

	# A distância das linhas até o centro mostra a imprecisão atual da arma.
	var gap := 3.0 + _spread_in_pixels()
	for dir in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
		var start: Vector2 = center + dir * gap
		var end: Vector2 = center + dir * (gap + CROSSHAIR_LENGTH)
		_crosshair.draw_line(start, end, Color.BLACK, CROSSHAIR_THICKNESS + 2.0)
		_crosshair.draw_line(start, end, CROSSHAIR_COLOR, CROSSHAIR_THICKNESS)
	_crosshair.draw_rect(Rect2(center - Vector2(1, 1), Vector2(2, 2)), CROSSHAIR_COLOR)


func _draw_scope() -> void:
	if not weapons.is_scoped:
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


func _spread_in_pixels() -> float:
	# A câmera usa FOV horizontal, então convertemos o ângulo em pixels pela largura da tela.
	var half_fov := deg_to_rad(player.camera.fov) / 2.0
	return tan(deg_to_rad(weapons.current_spread_deg())) / tan(half_fov) * _crosshair.size.x / 2.0


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
