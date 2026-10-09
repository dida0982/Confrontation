class_name BotDirector
extends Node
## "Técnico" dos bots. Existe só no servidor (host) e só quando a partida tem bots.
##
## - Cria a malha de navegação (NavigationRegion3D) a partir das caixas e paredes
##   do mapa quando a partida abre. Assim qualquer mapa novo funciona sem precisar
##   "assar" a malha no editor.
## - Lê as rotas do mapa: o nó "PontosBot" tem um filho por rota (A, Meio, B...)
##   e cada rota tem pontos (Marker3D) na ordem da base Azul para a Vermelha.
##   Sem esse nó, os bots andam por pontos sorteados da malha.
## - Divide os bots de cada time entre as rotas (não vão todos juntos).
## - Guarda os avisos do time ("vi um inimigo ali") e chama aliados para ajudar.
## - Escolhe de vez em quando um bot para acompanhar o jogador humano do time.

## Um bot do time avisou onde viu um inimigo.
signal enemy_reported(team: Team.Id, position: Vector3, reporter: Node)

## Quanto tempo (s) um aviso continua valendo.
const INTEL_LIFETIME := 6.0
## Quantos aliados no máximo atendem um mesmo aviso.
const MAX_HELPERS := 2
## Distância máxima (m) de um aliado para atender um aviso.
const HELP_DISTANCE := 40.0
## Intervalo (s) entre as trocas de quem acompanha o jogador humano.
const FOLLOW_SWAP_TIME := Vector2(35.0, 70.0)

var match_mode: TeamDeathmatch
var difficulty := 1
## A malha de navegação está pronta para os bots usarem.
var nav_ready := false
## Nome da rota -> pontos (Vector3) da base Azul para a Vermelha.
var lanes := {}

var _map_root: Node3D
var _region: NavigationRegion3D
## Time -> [{"position": Vector3, "time": float}]
var _intel := {Team.Id.AZUL: [], Team.Id.VERMELHO: []}
## Time -> bot que está acompanhando o humano (ou null).
var _followers := {Team.Id.AZUL: null, Team.Id.VERMELHO: null}
var _follow_timer := 10.0


func setup(p_match: TeamDeathmatch, p_map_root: Node3D, p_difficulty: int) -> void:
	match_mode = p_match
	_map_root = p_map_root
	difficulty = p_difficulty


func _ready() -> void:
	add_to_group("bot_director")
	_read_lanes()
	_bake_navigation.call_deferred()


func _process(delta: float) -> void:
	for team in _intel:
		var fresh: Array = []
		for entry in _intel[team]:
			if _now() - entry["time"] < INTEL_LIFETIME:
				fresh.append(entry)
		_intel[team] = fresh
	_follow_timer -= delta
	if _follow_timer <= 0.0:
		_follow_timer = randf_range(FOLLOW_SWAP_TIME.x, FOLLOW_SWAP_TIME.y)
		_pick_followers()


# --- Navegação ---------------------------------------------------------------

## Mapa de navegação do mundo (os bots pedem caminhos e pontos a ele).
func navigation_map() -> RID:
	return _region.get_world_3d().navigation_map if _region != null else RID()


## Ponto da malha mais perto de "point" (para saber se dá para andar ali).
func closest_walkable(point: Vector3) -> Vector3:
	return NavigationServer3D.map_get_closest_point(navigation_map(), point)


## true se dá para ficar em pé em "point" (está em cima da malha).
func is_walkable(point: Vector3, tolerance: float = 0.35) -> bool:
	var closest := closest_walkable(point)
	return Vector2(closest.x - point.x, closest.z - point.z).length() <= tolerance and absf(closest.y - point.y) < 1.0


func random_walkable_point() -> Vector3:
	return NavigationServer3D.map_get_random_point(navigation_map(), 1, true)


func _bake_navigation() -> void:
	var mesh := NavigationMesh.new()
	# Os números precisam bater com o mapa de navegação padrão (células de 0,25 m).
	mesh.cell_size = 0.25
	mesh.cell_height = 0.25
	mesh.agent_radius = 0.5
	mesh.agent_height = 1.75
	mesh.agent_max_climb = 0.5
	mesh.agent_max_slope = 46.0
	mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	mesh.geometry_collision_mask = 1

	_region = NavigationRegion3D.new()
	_region.name = "NavegacaoBots"
	_region.navigation_mesh = mesh
	_map_root.get_parent().add_child(_region)

	var source := _collect_geometry(mesh)
	NavigationServer3D.bake_from_source_geometry_data_async(mesh, source, func() -> void:
		_region.navigation_mesh = mesh
		# Espera o servidor de navegação montar o mapa antes de liberar os bots.
		await get_tree().physics_frame
		await get_tree().physics_frame
		nav_ready = true
	)


## Geometria do mapa para a malha. As caixas CSGBox3D com colisão viram caixas
## simples (rápido e sem ler a placa de vídeo); outros tipos de nó são lidos
## pelo próprio Godot.
func _collect_geometry(mesh: NavigationMesh) -> NavigationMeshSourceGeometryData3D:
	var source := NavigationMeshSourceGeometryData3D.new()
	var boxes := _map_root.find_children("*", "CSGBox3D", true, false)
	if boxes.is_empty():
		NavigationServer3D.parse_source_geometry_data(mesh, source, _map_root)
		return source
	for node in boxes:
		var box := node as CSGBox3D
		if not box.use_collision or box.operation != CSGShape3D.OPERATION_UNION:
			continue
		var shape := BoxMesh.new()
		shape.size = box.size
		source.add_mesh_array(shape.get_mesh_arrays(), box.global_transform)
	return source


# --- Rotas -------------------------------------------------------------------

func _read_lanes() -> void:
	var points := _map_root.get_parent().get_node_or_null("PontosBot")
	if points == null:
		return
	for lane in points.get_children():
		var list: Array[Vector3] = []
		for marker in lane.get_children():
			list.append((marker as Node3D).global_position)
		if list.size() >= 2:
			lanes[String(lane.name)] = list


## Pontos de uma rota na ordem certa para o time (sempre da própria base para a do inimigo).
func lane_points(lane: String, team: Team.Id) -> Array[Vector3]:
	var list: Array[Vector3] = []
	list.assign(lanes.get(lane, []))
	if team == Team.Id.VERMELHO:
		list.reverse()
	return list


## Escolhe a rota com menos bots do time (empate = sorteio). "avoid" = rota a evitar.
func choose_lane(bot: BotController, avoid: String = "") -> String:
	if lanes.is_empty():
		return ""
	var counts := {}
	for lane in lanes:
		counts[lane] = 0
	for other in get_tree().get_nodes_in_group("bot_brains"):
		if other != bot and (other as BotController).team() == bot.team() and counts.has(other.lane):
			counts[other.lane] += 1
	var options: Array = lanes.keys()
	options.shuffle()
	var best := ""
	var best_count := INF
	for lane in options:
		if lane == avoid and options.size() > 1:
			continue
		if counts[lane] < best_count:
			best_count = counts[lane]
			best = lane
	return best


## Rota onde o time viu inimigos por último (para flanquear por outra).
func hot_lane(team: Team.Id) -> String:
	var entries: Array = _intel[team]
	if entries.is_empty() or lanes.is_empty():
		return ""
	var position: Vector3 = entries[-1]["position"]
	var best := ""
	var best_distance := INF
	for lane in lanes:
		for point in lanes[lane]:
			var distance := (point as Vector3).distance_to(position)
			if distance < best_distance:
				best_distance = distance
				best = lane
	return best


# --- Avisos do time ----------------------------------------------------------

## Um bot viu um inimigo: guarda o aviso e chama até MAX_HELPERS aliados por perto.
func report_enemy(reporter: BotController, position: Vector3) -> void:
	var team := reporter.team()
	var entries: Array = _intel[team]
	# Não repete o mesmo aviso várias vezes por segundo.
	for entry in entries:
		if (entry["position"] as Vector3).distance_to(position) < 6.0 and _now() - entry["time"] < 1.5:
			return
	entries.append({"position": position, "time": _now()})
	enemy_reported.emit(team, position, reporter)

	var helpers: Array[BotController] = []
	for other in get_tree().get_nodes_in_group("bot_brains"):
		var bot := other as BotController
		if bot != reporter and bot.team() == team and bot.can_help(position, HELP_DISTANCE):
			helpers.append(bot)
	helpers.sort_custom(func(a: BotController, b: BotController) -> bool:
		return a.position().distance_to(position) < b.position().distance_to(position))
	for i in mini(helpers.size(), MAX_HELPERS):
		helpers[i].help_teammate(position)


## Avisos recentes do time: posições onde viram inimigos.
func recent_intel(team: Team.Id) -> Array[Vector3]:
	var result: Array[Vector3] = []
	for entry in _intel[team]:
		result.append(entry["position"])
	return result


# --- Acompanhar o jogador humano ---------------------------------------------

## Humano vivo do time que o bot deve acompanhar (ou null).
func follow_target(bot: BotController) -> Player:
	if _followers[bot.team()] != bot:
		return null
	for combatant in get_tree().get_nodes_in_group("combatants"):
		var player := combatant as Player
		if player != null and not player.is_bot and player.health.team == bot.team() and not player.health.is_dead:
			return player
	return null


func _pick_followers() -> void:
	for team in _followers:
		var candidates: Array = []
		for other in get_tree().get_nodes_in_group("bot_brains"):
			if (other as BotController).team() == team:
				candidates.append(other)
		# Metade das vezes ninguém acompanha (cada bot segue o próprio plano).
		_followers[team] = candidates.pick_random() if not candidates.is_empty() and randf() < 0.5 else null


static func _now() -> float:
	return Time.get_ticks_msec() / 1000.0
