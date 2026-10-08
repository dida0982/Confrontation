class_name TeamDeathmatch
extends Node
## Modo mata-mata em equipe (no estilo do Valorant):
## - cada abate de um inimigo vale 1 ponto para o time;
## - ganha quem chegar primeiro a "kills_to_win" abates,
##   ou quem tiver mais abates quando o tempo acabar (pode empatar);
## - quem morre renasce depois de "respawn_delay" segundos, num ponto de
##   nascimento do seu time, longe dos inimigos, com proteção por alguns segundos;
## - quem atira aparece no minimapa dos inimigos por "reveal_time" segundos.
##
## Tudo que pode lutar fica no grupo "combatants" e tem um nó filho "Health".
## Quem tem o método respawn(at, protection_time) é renascido por este script
## (o jogador). Os bonecos de treino renascem sozinhos.

signal kill_registered(killer: Node, victim: Node, headshot: bool)
## Abates ou mortes de alguém mudaram (o placar do Tab usa isso).
signal stats_changed
## winner é um Team.Id, ou -1 para empate.
signal match_ended(winner: int)

enum State { PLAYING, ENDED }

@export var kills_to_win := 100
## Tempo de partida em segundos (570 = 9:30).
@export var time_limit := 570.0
@export var respawn_delay := 3.0
@export var spawn_protection := 2.0
## Segundos que um jogador fica visível no minimapa dos inimigos depois de atirar.
@export var reveal_time := 3.0
## Nós cujos filhos (Marker3D) são os pontos de nascimento de cada time.
@export var spawns_azul: Node3D
@export var spawns_vermelho: Node3D

var state := State.PLAYING
var time_left := 0.0
var scores := {Team.Id.AZUL: 0, Team.Id.VERMELHO: 0}
var winner := -1

## Quem está esperando para renascer -> segundos que faltam.
var _respawn_timers := {}
## Combatente -> {"kills": int, "deaths": int}
var _stats := {}
## Combatente -> momento (em segundos) até quando aparece no minimapa dos inimigos.
var _revealed_until := {}


func _ready() -> void:
	time_left = time_limit
	_start.call_deferred()


func _start() -> void:
	for combatant in get_tree().get_nodes_in_group("combatants"):
		var health := _health_of(combatant)
		health.died.connect(_on_died.bind(combatant))
		_stats[combatant] = {"kills": 0, "deaths": 0}
		if combatant.has_signal("shot_fired"):
			combatant.shot_fired.connect(func() -> void: reveal(combatant))
		if combatant.has_method("respawn"):
			combatant.respawn(_pick_spawn(health.team), spawn_protection)


func _process(delta: float) -> void:
	if state != State.PLAYING:
		return

	time_left = maxf(time_left - delta, 0.0)
	if time_left == 0.0:
		_end_match()
		return

	for combatant in _respawn_timers.keys():
		_respawn_timers[combatant] -= delta
		if _respawn_timers[combatant] <= 0.0:
			_respawn_timers.erase(combatant)
			if is_instance_valid(combatant):
				combatant.respawn(_pick_spawn(_health_of(combatant).team), spawn_protection)


func _unhandled_input(event: InputEvent) -> void:
	if state == State.ENDED and event.is_action_pressed("restart_match"):
		get_tree().reload_current_scene()


## Abates e mortes de um combatente: {"kills": int, "deaths": int}.
func stats_of(combatant: Node) -> Dictionary:
	return _stats.get(combatant, {"kills": 0, "deaths": 0})


## Todos os combatentes de um time, do melhor para o pior (mais abates, menos mortes).
func ranking(team: Team.Id) -> Array[Node]:
	var members: Array[Node] = []
	for combatant in _stats:
		if is_instance_valid(combatant) and team_of(combatant) == team:
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


static func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


## Segundos até renascer (0 se não estiver esperando).
func respawn_time_left(combatant: Node) -> float:
	return _respawn_timers.get(combatant, 0.0)


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

	for team in scores:
		if scores[team] >= kills_to_win:
			_end_match()
			return


func _end_match() -> void:
	state = State.ENDED
	_respawn_timers.clear()
	var azul: int = scores[Team.Id.AZUL]
	var vermelho: int = scores[Team.Id.VERMELHO]
	if azul > vermelho:
		winner = Team.Id.AZUL
	elif vermelho > azul:
		winner = Team.Id.VERMELHO
	else:
		winner = -1
	for combatant in get_tree().get_nodes_in_group("combatants"):
		if "controls_enabled" in combatant:
			combatant.controls_enabled = false
	match_ended.emit(winner)


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
