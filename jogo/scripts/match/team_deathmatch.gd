class_name TeamDeathmatch
extends Node
## Modo mata-mata em equipe (no estilo do Valorant), funcionando em rede:
## - cada abate de um inimigo vale 1 ponto para o time;
## - ganha quem chegar primeiro a "kills_to_win" abates,
##   ou quem tiver mais abates quando o tempo acabar (pode empatar);
## - quem morre renasce depois de "respawn_delay" segundos, num ponto de
##   nascimento do seu time, longe dos inimigos, com proteção por alguns segundos;
## - quem atira aparece no minimapa dos inimigos por "reveal_time" segundos.
##
## Quem manda é o SERVIDOR (o host): ele cria os jogadores, confere os acertos,
## aplica o dano, conta o placar e decide quem renasce e quando a partida acaba.
## Os outros recebem esses eventos pelas funções _event_* (RPCs).
##
## Tudo que pode lutar fica no grupo "combatants" e tem um nó filho "Health".

signal kill_registered(killer: Node, victim: Node, headshot: bool)
## Abates ou mortes de alguém mudaram (o placar do Tab usa isso).
signal stats_changed
## winner é um Team.Id, ou -1 para empate.
signal match_ended(winner: int)
## O jogador deste computador apareceu no mapa (o HUD espera por ele).
signal local_player_spawned(player: Player)

enum State { WAITING, PLAYING, ENDED }

const PLAYER_SCENE := preload("res://scenes/player.tscn")
## Distância máxima (m) entre onde o atirador diz que estava e onde o servidor vê ele.
const HIT_ORIGIN_TOLERANCE := 4.0
const WORLD_MASK := 1

@export var kills_to_win := 100
## Tempo de partida em segundos (570 = 9:30).
@export var time_limit := 570.0
@export var respawn_delay := 3.0
@export var spawn_protection := 2.0
## Segundos que um jogador fica visível no minimapa dos inimigos depois de atirar.
@export var reveal_time := 3.0
## Tira os bonecos de treino quando tem mais de uma pessoa jogando.
@export var remove_dummies_online := true
## Nós cujos filhos (Marker3D) são os pontos de nascimento de cada time.
@export var spawns_azul: Node3D
@export var spawns_vermelho: Node3D
## Onde os jogadores são criados (o MultiplayerSpawner copia para todos).
@export var players_root: Node3D
@export var spawner: MultiplayerSpawner

var state := State.WAITING
var time_left := 0.0
var scores := {Team.Id.AZUL: 0, Team.Id.VERMELHO: 0}
var winner := -1
var local_player: Player

## Quem está esperando para renascer -> segundos que faltam.
var _respawn_timers := {}
## Combatente -> {"kills": int, "deaths": int}
var _stats := {}
## Combatente -> momento (em segundos) até quando aparece no minimapa dos inimigos.
var _revealed_until := {}
## Só no servidor: último acerto aceito de cada atirador (contra tiro rápido demais).
var _last_hit_time := {}
var _clock_timer := 0.0


func _ready() -> void:
	add_to_group("match")
	time_left = time_limit
	spawner.spawn_function = _spawn_player
	_setup.call_deferred()


func _setup() -> void:
	Rede.ensure_offline_player()
	if remove_dummies_online and Rede.players.size() > 1:
		for dummy in get_tree().get_nodes_in_group("training_dummy"):
			dummy.queue_free()
	for combatant in get_tree().get_nodes_in_group("combatants"):
		if not combatant.is_queued_for_deletion():
			_register_combatant(combatant)
	if multiplayer.is_server():
		Rede.all_loaded.connect(_start_match, CONNECT_ONE_SHOT)
		Rede.player_left.connect(_on_player_left)
	Rede.report_map_loaded()


func _process(delta: float) -> void:
	if state != State.PLAYING:
		return

	time_left = maxf(time_left - delta, 0.0)

	for combatant in _respawn_timers.keys():
		_respawn_timers[combatant] -= delta
		if _respawn_timers[combatant] <= 0.0:
			_respawn_timers.erase(combatant)
			if multiplayer.is_server() and is_instance_valid(combatant):
				_respawn(combatant)

	if multiplayer.is_server():
		_clock_timer += delta
		if _clock_timer >= 1.0:
			_clock_timer = 0.0
			_event_clock.rpc(time_left)
		if time_left == 0.0:
			_end_match()


func _unhandled_input(event: InputEvent) -> void:
	if state == State.ENDED and event.is_action_pressed("restart_match") and multiplayer.is_server():
		Rede.start_match(Rede.current_map)


# --- Consultas (usadas pelo HUD, placar e minimapa) -------------------------

## Abates e mortes de um combatente: {"kills": int, "deaths": int}.
func stats_of(combatant: Node) -> Dictionary:
	return _stats.get(combatant, {"kills": 0, "deaths": 0})


## Todos os combatentes de um time, do melhor para o pior (mais abates, menos mortes).
func ranking(team: Team.Id) -> Array[Node]:
	var members: Array[Node] = []
	for combatant in _stats:
		if is_instance_valid(combatant) and not combatant.is_queued_for_deletion() and team_of(combatant) == team:
			members.append(combatant)
	members.sort_custom(func(a: Node, b: Node) -> bool:
		var stats_a := stats_of(a)
		var stats_b := stats_of(b)
		if stats_a["kills"] != stats_b["kills"]:
			return stats_a["kills"] > stats_b["kills"]
		return stats_a["deaths"] < stats_b["deaths"]
	)
	return members


## Mostra o combatente no minimapa dos inimigos por "seconds" segundos.
func reveal(combatant: Node, seconds: float = reveal_time) -> void:
	_revealed_until[combatant] = _now() + seconds


## Quantos segundos ainda falta o combatente aparecer no minimapa dos inimigos (0 = escondido).
func reveal_time_left(combatant: Node) -> float:
	return maxf(_revealed_until.get(combatant, 0.0) - _now(), 0.0)


## Segundos até renascer (0 se não estiver esperando).
func respawn_time_left(combatant: Node) -> float:
	return _respawn_timers.get(combatant, 0.0)


# --- Pedidos do jogador local -----------------------------------------------

## O tiro do jogador local acertou alguém na tela dele: pede para o servidor conferir.
func report_hit(victim: Node, is_head: bool, weapon_index: int, origin: Vector3) -> void:
	_request_hit.rpc_id(1, victim.get_path(), is_head, weapon_index, origin)


## Só para teste (F8): o jogador local morre na hora.
func request_suicide() -> void:
	_request_suicide.rpc_id(1)


# --- Criação dos jogadores --------------------------------------------------

## Servidor: todos carregaram o mapa. Cria um jogador para cada pessoa.
func _start_match() -> void:
	_event_start.rpc()
	# Cada jogador do time começa num ponto de nascimento diferente.
	var next_spawn := {Team.Id.AZUL: 0, Team.Id.VERMELHO: 0}
	for id in Rede.players:
		var info: Dictionary = Rede.players[id]
		var team: Team.Id = info["team"]
		var spawns := spawns_azul if team == Team.Id.AZUL else spawns_vermelho
		var at := (spawns.get_child(next_spawn[team] % spawns.get_child_count()) as Node3D).global_transform
		next_spawn[team] += 1
		spawner.spawn({
			"id": id,
			"name": info["name"],
			"team": info["team"],
			"origin": at.origin,
			"yaw": at.basis.get_euler().y,
			"protection": spawn_protection,
		})


## Roda em TODOS os computadores quando o servidor cria um jogador.
func _spawn_player(data: Variant) -> Node:
	var info: Dictionary = data
	var id: int = info["id"]
	var player := PLAYER_SCENE.instantiate() as Player
	player.name = str(id)
	player.display_name = info["name"]
	(player.get_node("Health") as Health).team = info["team"]
	player.position = info["origin"]
	player.rotation.y = info["yaw"]
	player.spawn_protection_on_ready = info["protection"]
	player.set_multiplayer_authority(id)
	_register_combatant(player)
	if id == multiplayer.get_unique_id():
		local_player = player
		player.ready.connect(func() -> void: local_player_spawned.emit(player), CONNECT_ONE_SHOT)
	return player


func _register_combatant(combatant: Node) -> void:
	if _stats.has(combatant):
		return
	_stats[combatant] = {"kills": 0, "deaths": 0}
	_health_of(combatant).died.connect(_on_died.bind(combatant))
	if combatant.has_signal("shot_fired"):
		combatant.shot_fired.connect(_on_shot_fired.bind(combatant))
	stats_changed.emit()


func _on_player_left(id: int) -> void:
	var player := _player_by_id(id)
	if player != null:
		# O MultiplayerSpawner também remove o jogador nos outros computadores.
		player.queue_free()
		stats_changed.emit()


# --- Tiros, dano e mortes ---------------------------------------------------

func _on_shot_fired(combatant: Node) -> void:
	if combatant is Player:
		# Só o dono do jogador atira de verdade; ele avisa o servidor.
		if combatant.is_multiplayer_authority():
			_notify_shot.rpc_id(1, (combatant as Player).weapons.current_index)
	else:
		# Bonecos de treino: cada computador revela o seu.
		reveal(combatant)


@rpc("any_peer", "call_local", "reliable")
func _notify_shot(weapon_index: int) -> void:
	if not multiplayer.is_server():
		return
	var shooter := _player_by_id(_sender_id())
	if shooter != null and not shooter.health.is_dead:
		_event_shot.rpc(shooter.get_path(), weapon_index)


@rpc("any_peer", "call_local", "reliable")
func _request_hit(victim_path: NodePath, is_head: bool, weapon_index: int, origin: Vector3) -> void:
	if not multiplayer.is_server() or state != State.PLAYING:
		return
	var shooter := _player_by_id(_sender_id())
	var victim := get_node_or_null(victim_path)
	if not _is_valid_hit(shooter, victim, weapon_index, origin):
		return
	var weapon: WeaponData = shooter.weapons.weapons[weapon_index]
	var damage := weapon.head_damage if is_head else weapon.body_damage
	_apply_damage(victim, damage, is_head, shooter)


@rpc("any_peer", "call_local", "reliable")
func _request_suicide() -> void:
	if not multiplayer.is_server() or not OS.is_debug_build() or state != State.PLAYING:
		return
	var player := _player_by_id(_sender_id())
	if player != null and not player.health.is_dead:
		player.health.invulnerable = false
		_apply_damage(player, player.health.max_health, false, null)


## Servidor: confere se o acerto que o atirador mandou é possível.
func _is_valid_hit(shooter: Player, victim: Node, weapon_index: int, origin: Vector3) -> bool:
	if shooter == null or victim == null or shooter.health.is_dead:
		return false
	if not victim.has_node("Health"):
		return false
	var victim_health := _health_of(victim)
	if victim_health.is_dead or victim_health.team == shooter.health.team:
		return false
	if weapon_index < 0 or weapon_index >= shooter.weapons.weapons.size():
		return false
	var weapon: WeaponData = shooter.weapons.weapons[weapon_index]

	# Cadência: não dá para acertar mais rápido do que a arma atira.
	var now := _now()
	if now - _last_hit_time.get(shooter, -INF) < weapon.fire_interval * 0.5:
		return false

	# O tiro precisa sair de perto de onde o servidor vê o atirador.
	if origin.distance_to(shooter.camera.global_position) > HIT_ORIGIN_TOLERANCE:
		return false

	var victim_3d := victim as Node3D
	if origin.distance_to(victim_3d.global_position) > weapon.max_range + 2.0:
		return false

	# Precisa enxergar a cabeça ou o corpo (sem parede no meio).
	var targets := [victim_3d.global_position + Vector3.UP * 1.6, victim_3d.global_position + Vector3.UP * 0.9]
	var can_see := false
	for target in targets:
		var query := PhysicsRayQueryParameters3D.create(origin, target, WORLD_MASK)
		if get_viewport().get_world_3d().direct_space_state.intersect_ray(query).is_empty():
			can_see = true
			break
	if not can_see:
		return false

	_last_hit_time[shooter] = now
	return true


## Servidor: aplica o dano e avisa todo mundo.
func _apply_damage(victim: Node, damage: int, headshot: bool, attacker: Node) -> void:
	var health := _health_of(victim)
	var before := health.current
	var killed := health.take_damage(damage, headshot, attacker)
	if health.current == before and not killed:
		return
	var attacker_path := attacker.get_path() if attacker != null else NodePath()
	_event_damage.rpc(victim.get_path(), damage, headshot, health.current, attacker_path, killed)


## Roda em todos (o servidor também) quando alguém morre.
func _on_died(killer: Node, headshot: bool, victim: Node) -> void:
	if state != State.PLAYING:
		return

	var victim_team := _health_of(victim).team
	stats_of(victim)["deaths"] += 1
	_revealed_until.erase(victim)
	if killer != null and killer != victim and _health_of(killer).team != victim_team:
		scores[_health_of(killer).team] += 1
		stats_of(killer)["kills"] += 1
	stats_changed.emit()

	kill_registered.emit(killer, victim, headshot)

	if victim.has_method("respawn"):
		_respawn_timers[victim] = respawn_delay

	if multiplayer.is_server():
		# Depois de mandar o evento de dano, para todos verem o último abate.
		_check_score_limit.call_deferred()


func _check_score_limit() -> void:
	if state != State.PLAYING:
		return
	for team in scores:
		if scores[team] >= kills_to_win:
			_end_match()
			return


func _respawn(combatant: Node) -> void:
	var at := _pick_spawn(_health_of(combatant).team)
	_event_respawn.rpc(combatant.get_path(), at, spawn_protection)


func _end_match() -> void:
	if state != State.PLAYING:
		return
	var azul: int = scores[Team.Id.AZUL]
	var vermelho: int = scores[Team.Id.VERMELHO]
	var result := -1
	if azul > vermelho:
		result = Team.Id.AZUL
	elif vermelho > azul:
		result = Team.Id.VERMELHO
	_event_end.rpc(result, azul, vermelho)


# --- Eventos que o servidor manda para todos --------------------------------

@rpc("authority", "call_local", "reliable")
func _event_start() -> void:
	state = State.PLAYING


@rpc("authority", "call_remote", "reliable")
func _event_damage(victim_path: NodePath, damage: int, headshot: bool, health_now: int, killer_path: NodePath, killed: bool) -> void:
	var victim := get_node_or_null(victim_path)
	if victim == null:
		return
	var killer: Node = null
	if not killer_path.is_empty():
		killer = get_node_or_null(killer_path)
	_health_of(victim).apply_from_server(health_now, damage, headshot, killer, killed)


@rpc("authority", "call_local", "reliable")
func _event_shot(shooter_path: NodePath, weapon_index: int) -> void:
	var shooter := get_node_or_null(shooter_path)
	if shooter == null:
		return
	reveal(shooter)
	# Quem atirou já ouviu o próprio tiro; os outros ouvem vindo do boneco dele.
	if shooter is Player and not (shooter as Player).is_local():
		(shooter as Player).play_remote_shot(weapon_index)
	# Atirar cancela a proteção de nascimento.
	_health_of(shooter).invulnerable = false


@rpc("authority", "call_local", "reliable")
func _event_respawn(path: NodePath, at: Transform3D, protection: float) -> void:
	var combatant := get_node_or_null(path)
	if combatant == null:
		return
	_respawn_timers.erase(combatant)
	combatant.respawn(at, protection)


@rpc("authority", "call_remote", "unreliable")
func _event_clock(server_time_left: float) -> void:
	time_left = server_time_left


@rpc("authority", "call_local", "reliable")
func _event_end(result: int, azul: int, vermelho: int) -> void:
	state = State.ENDED
	winner = result
	scores[Team.Id.AZUL] = azul
	scores[Team.Id.VERMELHO] = vermelho
	_respawn_timers.clear()
	for combatant in get_tree().get_nodes_in_group("combatants"):
		if "controls_enabled" in combatant:
			combatant.controls_enabled = false
	match_ended.emit(winner)


# --- Ajudantes ---------------------------------------------------------------

## Escolhe o ponto de nascimento do time que está mais longe do inimigo vivo mais próximo.
func _pick_spawn(team: Team.Id) -> Transform3D:
	var spawns := spawns_azul if team == Team.Id.AZUL else spawns_vermelho
	var enemies: Array[Vector3] = []
	for combatant in get_tree().get_nodes_in_group("combatants"):
		var health := _health_of(combatant)
		if health.team != team and not health.is_dead:
			enemies.append((combatant as Node3D).global_position)

	var best: Node3D = null
	var best_distance := -1.0
	for spawn in spawns.get_children():
		var point := spawn as Node3D
		var nearest := INF
		for enemy in enemies:
			nearest = minf(nearest, point.global_position.distance_to(enemy))
		if nearest > best_distance:
			best_distance = nearest
			best = point
	return best.global_transform


func _player_by_id(id: int) -> Player:
	return players_root.get_node_or_null(str(id)) as Player


func _sender_id() -> int:
	var id := multiplayer.get_remote_sender_id()
	return id if id != 0 else multiplayer.get_unique_id()


static func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


static func _health_of(combatant: Node) -> Health:
	return combatant.get_node("Health") as Health


## Nome para mostrar no feed de abates.
static func name_of(combatant: Node) -> String:
	if combatant == null:
		return ""
	var display_name = combatant.get("display_name")
	return display_name if display_name != null else String(combatant.name)


static func team_of(combatant: Node) -> Team.Id:
	return _health_of(combatant).team
