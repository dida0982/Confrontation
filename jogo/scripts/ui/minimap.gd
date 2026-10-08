class_name Minimap
extends Control
## Minimapa no canto da tela, no estilo do Valorant (norte sempre para cima).
##
## - O desenho do mapa é montado sozinho a partir das caixas (CSGBox3D) do nó
##   do mapa. Por isso funciona em qualquer mapa feito com caixas, sem configurar nada.
## - Você aparece como uma seta amarela com o cone de visão.
## - Aliados aparecem sempre (azul).
## - Inimigos só aparecem depois de atirar, por alguns segundos (vermelho).
## - Labels 3D no grupo "minimap_label" (ex.: "A", "B") são escritos no minimapa.

## Tamanho do lado maior do minimapa, em pixels (o outro lado segue o formato do mapa).
const MAP_SIZE := 260.0
const PADDING := 8.0
const ICON_RADIUS := 5.0
## Abaixo desta altura (m) a caixa é chão; acima de WALL_HEIGHT é parede.
const FLOOR_HEIGHT := 0.05
const WALL_HEIGHT := 2.5

const BACKGROUND_COLOR := Color(0.0, 0.0, 0.0, 0.45)
const FLOOR_COLOR := Color(0.56, 0.59, 0.64, 0.9)
const COVER_COLOR := Color(0.3, 0.32, 0.37, 0.95)
const WALL_COLOR := Color(0.13, 0.14, 0.16, 0.95)
const BORDER_COLOR := Color(1, 1, 1, 0.25)
const SELF_COLOR := Color(1.0, 0.85, 0.3)
const VIEW_CONE_COLOR := Color(1.0, 0.85, 0.3, 0.18)
const VIEW_CONE_LENGTH := 46.0
## Quanto tempo o "pulso" aparece em volta do inimigo logo depois do tiro.
const PULSE_TIME := 0.5

var match_mode: TeamDeathmatch
var local_player: Player
var map_root: Node3D

## Cada item: {"rect": Rect2 (em metros, plano xz), "color": Color}
var _shapes: Array[Dictionary] = []
## Cada item: {"position": Vector2 (metros), "text": String}
var _labels: Array[Dictionary] = []
var _bounds := Rect2()
var _scale := 1.0
var _offset := Vector2.ZERO


func _init(p_match: TeamDeathmatch, p_player: Player, p_map_root: Node3D) -> void:
	match_mode = p_match
	local_player = p_player
	map_root = p_map_root
	size = Vector2(MAP_SIZE, MAP_SIZE)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	_read_map()


func _process(_delta: float) -> void:
	queue_redraw()


# --- Leitura do mapa --------------------------------------------------------

func _read_map() -> void:
	var floors: Array[Dictionary] = []
	var zones: Array[Dictionary] = []
	var covers: Array[Dictionary] = []
	var walls: Array[Dictionary] = []
	var have_bounds := false

	for box in _find_boxes(map_root):
		var rect := _box_rect_xz(box)
		var top := _box_top(box)
		if not box.use_collision:
			zones.append({"rect": rect, "color": _zone_color(box)})
			continue
		if not have_bounds:
			_bounds = rect
			have_bounds = true
		else:
			_bounds = _bounds.merge(rect)
		if top <= FLOOR_HEIGHT:
			floors.append({"rect": rect, "color": FLOOR_COLOR})
		elif top >= WALL_HEIGHT:
			walls.append({"rect": rect, "color": WALL_COLOR})
		else:
			covers.append({"rect": rect, "color": COVER_COLOR})

	# Ordem de desenho: chão, áreas coloridas, coberturas, paredes.
	_shapes = floors + zones + covers + walls

	for node in get_tree().get_nodes_in_group("minimap_label"):
		var label := node as Label3D
		if label != null and map_root.is_ancestor_of(label):
			var pos := label.global_position
			_labels.append({"position": Vector2(pos.x, pos.z), "text": label.text})

	var usable := MAP_SIZE - PADDING * 2.0
	_scale = minf(usable / maxf(_bounds.size.x, 0.001), usable / maxf(_bounds.size.y, 0.001))
	var drawn_size := _bounds.size * _scale
	size = drawn_size + Vector2(PADDING, PADDING) * 2.0
	_offset = Vector2(PADDING, PADDING) - _bounds.position * _scale


func _find_boxes(node: Node) -> Array[CSGBox3D]:
	var result: Array[CSGBox3D] = []
	for child in node.get_children():
		if child is CSGBox3D:
			result.append(child)
		result.append_array(_find_boxes(child))
	return result


## Retângulo que a caixa ocupa visto de cima (funciona mesmo com caixa girada).
func _box_rect_xz(box: CSGBox3D) -> Rect2:
	var half := box.size / 2.0
	var min_point := Vector2(INF, INF)
	var max_point := Vector2(-INF, -INF)
	for corner in _corners(half):
		var world := box.global_transform * corner
		min_point = min_point.min(Vector2(world.x, world.z))
		max_point = max_point.max(Vector2(world.x, world.z))
	return Rect2(min_point, max_point - min_point)


func _box_top(box: CSGBox3D) -> float:
	var top := -INF
	for corner in _corners(box.size / 2.0):
		top = maxf(top, (box.global_transform * corner).y)
	return top


func _corners(half: Vector3) -> Array[Vector3]:
	var corners: Array[Vector3] = []
	for x in [-1.0, 1.0]:
		for y in [-1.0, 1.0]:
			for z in [-1.0, 1.0]:
				corners.append(Vector3(half.x * x, half.y * y, half.z * z))
	return corners


func _zone_color(box: CSGBox3D) -> Color:
	var color := Color(1, 1, 1)
	var material := box.material as ShaderMaterial
	if material != null and material.get_shader_parameter("base_color") != null:
		color = material.get_shader_parameter("base_color")
	elif box.material is StandardMaterial3D:
		color = (box.material as StandardMaterial3D).albedo_color
	color.a = 0.6
	return color


# --- Desenho ----------------------------------------------------------------

func _to_minimap(world_xz: Vector2) -> Vector2:
	return world_xz * _scale + _offset


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BACKGROUND_COLOR)
	for shape in _shapes:
		var rect: Rect2 = shape["rect"]
		draw_rect(Rect2(_to_minimap(rect.position), rect.size * _scale), shape["color"])

	var font := get_theme_default_font()
	for label in _labels:
		var text: String = label["text"]
		var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18)
		var at := _to_minimap(label["position"]) + Vector2(-text_size.x / 2.0, text_size.y / 3.0)
		draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, 4, Color(0, 0, 0, 0.7))
		draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)

	_draw_combatants()
	draw_rect(Rect2(Vector2.ZERO, size), BORDER_COLOR, false, 1.0)


func _draw_combatants() -> void:
	# O jogador some quando a partida acaba ou a conexão cai.
	if not is_instance_valid(local_player) or not local_player.is_inside_tree():
		return
	var my_team := local_player.health.team
	for combatant in get_tree().get_nodes_in_group("combatants"):
		if combatant == local_player or not combatant.is_inside_tree():
			continue
		var health := combatant.get_node("Health") as Health
		if health.is_dead:
			continue
		var at := _to_minimap(_xz(combatant as Node3D))
		if health.team == my_team:
			_draw_icon(at, Team.color_of(health.team))
			continue
		var time_left := match_mode.reveal_time_left(combatant)
		if time_left <= 0.0:
			continue
		var color := Team.color_of(health.team)
		# Pisca nos últimos instantes antes de sumir.
		if time_left < 0.6:
			color.a = 0.4 + 0.6 * absf(sin(time_left * 20.0))
		_draw_icon(at, color)
		var since_shot := match_mode.reveal_time - time_left
		if since_shot < PULSE_TIME:
			var t := since_shot / PULSE_TIME
			draw_arc(at, ICON_RADIUS + 10.0 * t, 0.0, TAU, 24, Color(color, 1.0 - t), 2.0)

	if not local_player.health.is_dead:
		_draw_self()


func _draw_icon(at: Vector2, color: Color) -> void:
	draw_circle(at, ICON_RADIUS + 1.5, Color(0, 0, 0, color.a))
	draw_circle(at, ICON_RADIUS, color)


func _draw_self() -> void:
	var at := _to_minimap(_xz(local_player))
	var forward3 := -local_player.global_basis.z
	var forward := Vector2(forward3.x, forward3.z).normalized()

	# Cone de visão (usa o mesmo campo de visão da câmera).
	var half_fov := deg_to_rad(local_player.camera.fov) / 2.0
	var cone := PackedVector2Array([at])
	for i in 9:
		var angle := lerpf(-half_fov, half_fov, i / 8.0)
		cone.append(at + forward.rotated(angle) * VIEW_CONE_LENGTH)
	draw_colored_polygon(cone, VIEW_CONE_COLOR)

	# Seta apontando para onde você olha.
	var tip := at + forward * 9.0
	var left := at + forward.rotated(deg_to_rad(140.0)) * 7.0
	var right := at + forward.rotated(deg_to_rad(-140.0)) * 7.0
	var back := at - forward * 2.5
	var arrow := PackedVector2Array([tip, left, back, right])
	draw_colored_polygon(arrow, SELF_COLOR)
	draw_polyline(PackedVector2Array([tip, left, back, right, tip]), Color.BLACK, 1.5)


static func _xz(node: Node3D) -> Vector2:
	return Vector2(node.global_position.x, node.global_position.z)
