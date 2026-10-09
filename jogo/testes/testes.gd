extends Node
## Testes automáticos do Confrontation. Rodam sem abrir janela:
##
##   Godot_v4.7.2-stable_win64_console.exe --headless --path jogo -s res://testes/rodar_testes.gd
##
## Cada teste imprime OK ou FALHOU. No fim, o programa sai com o número de
## falhas (0 = tudo certo), então dá para usar em scripts.
## Para rodar só alguns: --  dano bots   (nomes depois de "--").

const SALA_DE_TREINO := "res://scenes/sala_de_treino.tscn"

var _failures := 0
var _current := ""


func _ready() -> void:
	_run_all.call_deferred()


func _run_all() -> void:
	var only := OS.get_cmdline_user_args()
	var tests := [
		["nomes", _test_nomes],
		["bots_por_time", _test_bots_por_time],
		["dano", _test_dano],
		["tiro_de_verdade", _test_tiro_de_verdade],
		["protecao_de_nascimento", _test_protecao],
		["rotas_dos_bots", _test_rotas_dos_bots],
		["partida_com_bots", _test_partida_com_bots],
		["fim_de_partida", _test_fim_de_partida],
	]
	var started := Time.get_ticks_msec()
	for test in tests:
		if not only.is_empty() and not only.has(test[0]):
			continue
		_current = test[0]
		var failures_before := _failures
		await (test[1] as Callable).call()
		if _failures == failures_before:
			print("OK      ", _current)
		await _leave_match()
	print("\n%s  (%d falha(s), %.1f s)" % ["TUDO CERTO" if _failures == 0 else "TEM FALHA", _failures, (Time.get_ticks_msec() - started) / 1000.0])
	get_tree().quit(_failures)


# --- Testes ------------------------------------------------------------------

func _test_nomes() -> void:
	_check(Rede.clean_name("  Ana  ") == "Ana", "tira espaços do nome")
	_check(Rede.clean_name("") == "Jogador", "nome vazio vira Jogador")
	_check(Rede.clean_name("[b]x[/b]") == "bx/b", "tira colchetes (BBCode do feed de abates)")
	_check(Rede.clean_name("abcdefghijklmnopqrstuvwxyz").length() == Rede.MAX_NAME_LENGTH, "corta nome comprido")


func _test_bots_por_time() -> void:
	Rede.players = {1: {"name": "A", "team": Team.Id.AZUL}, 2: {"name": "B", "team": Team.Id.AZUL}, 3: {"name": "C", "team": Team.Id.VERMELHO}}
	Rede.bots_enabled = false
	_check(Rede.bots_needed(Team.Id.AZUL) == 0, "sem bots ligados, nenhum bot")
	Rede.bots_enabled = true
	_check(Rede.bots_needed(Team.Id.AZUL) == 3, "2 pessoas no Azul -> 3 bots")
	_check(Rede.bots_needed(Team.Id.VERMELHO) == 4, "1 pessoa no Vermelho -> 4 bots")
	Rede.players = {}
	Rede.bots_enabled = false


func _test_dano() -> void:
	var match_mode := await _open_training()
	var dummy := _first_dummy()
	var health := dummy.get_node("Health") as Health
	var shooter := match_mode.local_player
	for i in 3:
		match_mode._apply_damage(dummy, 25, false, shooter)
	_check(health.current == 25 and not health.is_dead, "3 tiros no corpo deixam 25 de vida")
	match_mode._apply_damage(dummy, 25, false, shooter)
	_check(health.is_dead, "4º tiro no corpo mata")
	_check(match_mode.stats_of(shooter)["kills"] == 1, "abate conta para quem atirou")
	_check(match_mode.scores[Team.Id.AZUL] == 1, "abate vale 1 ponto para o time")
	var other := _dummies()[1] as Node
	match_mode._apply_damage(other, 100, true, shooter)
	_check((other.get_node("Health") as Health).is_dead, "tiro na cabeça mata")


func _test_tiro_de_verdade() -> void:
	var match_mode := await _open_training()
	var player := match_mode.local_player
	var dummy := _first_dummy()
	var health := dummy.get_node("Health") as Health
	# Fica 6 m na frente do boneco e mira no peito.
	player.global_position = dummy.global_position + Vector3(0, 0, 6)
	player.health.invulnerable = false
	await get_tree().physics_frame
	_aim(player, dummy.global_position + Vector3.UP * 1.0)
	player.weapons.equip(0)
	player.weapons._equip_timer = 0.0
	await get_tree().physics_frame
	player.weapons._try_fire()
	await get_tree().create_timer(0.1).timeout
	_check(health.current == 75, "fuzil no peito tira 25 (vida %d)" % health.current)
	# Cabeça.
	_aim(player, (dummy.get_node("Hitboxes/Head") as Node3D).global_position)
	await get_tree().physics_frame
	await get_tree().create_timer(0.15).timeout
	player.weapons._try_fire()
	await get_tree().create_timer(0.1).timeout
	_check(health.is_dead, "fuzil na cabeça mata")
	# Sniper no corpo do mesmo boneco, depois que ele renasce (com zoom não tem imprecisão).
	await get_tree().create_timer((dummy.get("respawn_time") as float) + 0.3).timeout
	_check(health.current == 100, "boneco de treino renasce com vida cheia")
	_aim(player, dummy.global_position + Vector3.UP * 0.9)
	player.weapons.equip(2)
	player.weapons._equip_timer = 0.0
	player.weapons.set_scoped(true)
	await get_tree().physics_frame
	player.weapons._try_fire()
	await get_tree().create_timer(0.1).timeout
	_check(health.is_dead, "sniper no corpo mata com 1 tiro")


func _test_protecao() -> void:
	var match_mode := await _open_training()
	var player := match_mode.local_player
	player.health.invulnerable = true
	match_mode._apply_damage(player, 100, true, null)
	_check(not player.health.is_dead and player.health.current == 100, "proteção de nascimento bloqueia o dano")
	player.health.invulnerable = false
	match_mode._apply_damage(player, 25, false, null)
	_check(player.health.current == 75, "sem proteção leva dano")


func _test_rotas_dos_bots() -> void:
	var match_mode := await _open_bots(1)
	var director := match_mode.bot_director
	_check(director.lanes.size() == 3, "o Porto tem as rotas A, Meio e B")
	for lane in director.lanes:
		for point in director.lanes[lane]:
			_check(director.is_walkable(point, 0.6), "ponto %s da rota %s fica no chão andável (mais perto: %s)" % [point, lane, director.closest_walkable(point)])
	for spawns in [match_mode.spawns_azul, match_mode.spawns_vermelho]:
		for spawn in spawns.get_children():
			_check(director.is_walkable((spawn as Node3D).global_position, 0.6), "nascimento %s fica no chão andável" % spawn.name)


func _test_partida_com_bots() -> void:
	var match_mode := await _open_bots(1)
	var human := match_mode.local_player
	human.controls_enabled = false
	var brains := get_tree().get_nodes_in_group("bot_brains")
	_check(brains.size() == 9, "9 bots (4 aliados + 5 inimigos), tem %d" % brains.size())
	var kills := [0]
	match_mode.kill_registered.connect(func(_k: Node, _v: Node, _h: bool) -> void: kills[0] += 1)
	var start := {}
	var last := {}
	var still := {}
	var worst_still := 0
	for brain in brains:
		start[brain] = brain.player.global_position
	for second in 45:
		await get_tree().create_timer(1.0).timeout
		for brain in brains:
			var bot: Player = brain.player
			var moved: float = bot.global_position.distance_to(last.get(brain, Vector3.ZERO))
			last[brain] = bot.global_position
			var fighting: bool = brain.state in [BotController.State.COMBATER, BotController.State.COBERTURA]
			still[brain] = 0 if bot.health.is_dead or fighting or moved > 0.3 else still.get(brain, 0) + 1
			worst_still = maxi(worst_still, still[brain])
	var moved_bots := 0
	for brain in brains:
		if (brain.player as Player).global_position.distance_to(start[brain]) > 3.0 or match_mode.stats_of(brain.player)["deaths"] > 0:
			moved_bots += 1
	_check(moved_bots == brains.size(), "todos os bots saíram do lugar (%d de %d)" % [moved_bots, brains.size()])
	_check(kills[0] >= 5, "bots lutam e matam (%d abates em 45 s)" % kills[0])
	_check(worst_still <= 6, "nenhum bot ficou parado mais de 6 s fora de combate (pior: %d s)" % worst_still)
	_check(match_mode.scores[Team.Id.AZUL] + match_mode.scores[Team.Id.VERMELHO] == kills[0], "placar bate com os abates")


func _test_fim_de_partida() -> void:
	var match_mode := await _open_bots(2)
	match_mode.kills_to_win = 3
	var ended := [false]
	match_mode.match_ended.connect(func(_winner: int) -> void: ended[0] = true)
	for second in 60:
		await get_tree().create_timer(1.0).timeout
		if ended[0]:
			break
	_check(ended[0], "a partida acaba quando um time chega no limite de abates")
	_check(match_mode.winner != -1 and match_mode.scores[match_mode.winner] >= 3, "o vencedor tem 3 abates")
	var all_stopped := true
	for brain in get_tree().get_nodes_in_group("bot_brains"):
		all_stopped = all_stopped and not (brain.player as Player).can_act()
	_check(all_stopped, "ninguém se mexe depois do fim")


# --- Ajudantes ---------------------------------------------------------------

func _check(condition: bool, description: String) -> void:
	if not condition:
		_failures += 1
		print("FALHOU  ", _current, ": ", description)


func _open_training() -> TeamDeathmatch:
	Rede.play_offline("Teste", SALA_DE_TREINO)
	return await _wait_match()


func _open_bots(difficulty: int) -> TeamDeathmatch:
	Rede.play_vs_bots("Teste", difficulty)
	var match_mode := await _wait_match()
	while not match_mode.bot_director.nav_ready:
		await get_tree().physics_frame
	return match_mode


func _wait_match() -> TeamDeathmatch:
	for i in 300:
		await get_tree().process_frame
		var match_mode := get_tree().get_first_node_in_group("match") as TeamDeathmatch
		if match_mode != null and match_mode.local_player != null and match_mode.local_player.is_inside_tree():
			await get_tree().physics_frame
			return match_mode
	push_error("a partida não abriu")
	return null


func _leave_match() -> void:
	Rede.leave()
	await get_tree().process_frame
	await get_tree().process_frame


func _dummies() -> Array[Node]:
	var list := get_tree().get_nodes_in_group("training_dummy")
	list.sort_custom(func(a: Node, b: Node) -> bool: return String(a.name) < String(b.name))
	return list


func _first_dummy() -> Node3D:
	return _dummies()[0] as Node3D


## Vira o jogador e a câmera para mirar num ponto.
func _aim(player: Player, point: Vector3) -> void:
	var to := point - player.camera.global_position
	player.rotation.y = atan2(-to.x, -to.z)
	player.look_pitch = atan2(to.y, Vector2(to.x, to.z).length())
	player.camera.rotation.x = player.look_pitch
