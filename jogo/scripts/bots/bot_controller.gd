class_name BotController
extends Node
## Cérebro de um bot. Fica dentro de um Player (o mesmo boneco dos jogadores) e,
## em vez de teclado e mouse, preenche player.input_* (andar, correr, agachar,
## pular), gira a câmera (mira) e usa as armas pelo WeaponManager.
## Só existe no host (servidor); para os outros o bot é um jogador normal.
##
## O bot só sabe o que um jogador saberia:
## - VÊ inimigos dentro do campo de visão e sem parede no meio;
## - OUVE tiros e passos de quem corre por perto;
## - vê no "minimapa" quem atirou (como os jogadores);
## - recebe os avisos dos aliados (BotDirector).
##
## Comportamentos (máquina de estados):
## - PATRULHAR: anda pela rota (A, Meio ou B), parando e olhando as quinas;
## - COMBATER: mira com tempo de reação e erro (como uma pessoa), atira em
##   rajadas, faz strafe, às vezes agacha e escolhe a arma pela distância;
## - COBERTURA: vai para trás de uma parede para recarregar ou fugir de 2+ inimigos;
## - INVESTIGAR: vai até onde ouviu um tiro, viu alguém ou um aliado avisou;
## - SEGUIR: acompanha o jogador humano do time por um tempo.
## Flanquear: ao trocar de rota, às vezes escolhe outra que não a dos inimigos.

enum Difficulty { FACIL, NORMAL, DIFICIL }
enum State { PATRULHAR, COMBATER, COBERTURA, INVESTIGAR, SEGUIR }

const DIFFICULTY_NAMES := ["Fácil", "Normal", "Difícil"]

## Números de cada dificuldade.
## reaction: segundos entre ver e atirar. turn_rate: quão rápido a mira chega no alvo.
## aim_error/aim_error_min: erro da mira em metros (começa grande e melhora até o mínimo).
## settle_time: segundos para a mira "assentar". head_chance: chance de mirar na cabeça.
## strafe_chance / crouch_chance / cover_chance / flank_chance / sniper_chance: 0 a 1.
## burst/burst_pause: duração das rajadas e pausas (s). view_distance: alcance da visão.
const PROFILES := {
	Difficulty.FACIL: {
		"reaction": 0.65, "turn_rate": 6.0, "aim_error": 1.0, "aim_error_min": 0.32, "settle_time": 1.4,
		"head_chance": 0.08, "strafe_chance": 0.3, "crouch_chance": 0.05, "cover_chance": 0.25,
		"flank_chance": 0.1, "sniper_chance": 0.1, "burst": Vector2(0.1, 0.25), "burst_pause": Vector2(0.4, 0.8),
		"view_distance": 50.0, "fov_degrees": 100.0,
	},
	Difficulty.NORMAL: {
		"reaction": 0.4, "turn_rate": 9.0, "aim_error": 0.65, "aim_error_min": 0.17, "settle_time": 0.9,
		"head_chance": 0.25, "strafe_chance": 0.65, "crouch_chance": 0.15, "cover_chance": 0.6,
		"flank_chance": 0.25, "sniper_chance": 0.25, "burst": Vector2(0.15, 0.4), "burst_pause": Vector2(0.2, 0.45),
		"view_distance": 70.0, "fov_degrees": 110.0,
	},
	Difficulty.DIFICIL: {
		"reaction": 0.25, "turn_rate": 13.0, "aim_error": 0.4, "aim_error_min": 0.07, "settle_time": 0.55,
		"head_chance": 0.5, "strafe_chance": 0.9, "crouch_chance": 0.3, "cover_chance": 0.85,
		"flank_chance": 0.4, "sniper_chance": 0.35, "burst": Vector2(0.25, 0.6), "burst_pause": Vector2(0.1, 0.25),
		"view_distance": 90.0, "fov_degrees": 120.0,
	},
}

const FUZIL := 0
const PISTOLA := 1
const SNIPER := 2
const WORLD_MASK := 1
const EYE_HEIGHT := 1.5
## Intervalo (s) entre uma "olhada" e outra (ver e ouvir).
const PERCEPTION_INTERVAL := 0.1
## Distância (m) em que o bot percebe um inimigo mesmo de costas.
const SENSE_DISTANCE := 3.0
## Ouve passos de quem corre até esta distância (m).
const FOOTSTEP_HEARING := 18.0
## Ouve tiros até esta distância (m).
const SHOT_HEARING := 60.0
## Segundos sem ver o alvo até ir procurar onde ele estava.
const LOST_TARGET_TIME := 0.7
## Distância (m) a partir da qual usa a sniper (se gostar de sniper).
const SNIPER_DISTANCE := 28.0
## Abaixo desta distância (m), sem bala no fuzil, saca a pistola em vez de recarregar.
const PISTOL_SWITCH_DISTANCE := 15.0
## Velocidade (m/s) abaixo da qual o bot está "preso" quando quer andar.
const STUCK_SPEED := 0.6

var director: BotDirector
var state := State.PATRULHAR
## Rota atual (nome de um filho do nó PontosBot).
var lane := ""

var player: Player
var profile: Dictionary
var _agent: NavigationAgent3D

# Visão e memória
var _perception_timer := 0.0
var _visible_enemies: Array[Player] = []
var _target: Player
var _last_seen_position := Vector3.ZERO
var _last_seen_time := -INF
var _reaction_timer := 0.0
var _aim_offset := Vector3.ZERO
var _aim_at_head := false
var _engaged_time := 0.0

# Mira (para onde a câmera está virando)
var _look_point := Vector3.ZERO
var _has_look_point := false
var _turn_rate := 9.0

# Tiro
var _burst_timer := 0.0
var _pause_timer := 0.0
var _weapon_think_timer := 0.0
var _likes_sniper := false
var _calm_time := 0.0

# Movimento
var _strafe_dir := 1.0
var _strafe_timer := 0.0
var _crouch_spray := false
var _stuck_time := 0.0
var _unstuck_timer := 0.0
var _unstuck_dir := Vector3.ZERO

# Estados
var _lane_points: Array[Vector3] = []
var _lane_index := 0
var _lane_step := 1
var _wait_timer := 0.0
var _glance_timer := 0.0
var _goal := Vector3.ZERO
var _goal_timeout := 0.0
var _cover_point := Vector3.ZERO
var _cover_threat := Vector3.ZERO
var _was_dead := true


func _ready() -> void:
	player = get_parent() as Player
	add_to_group("bot_brains")
	# Pensa antes do Player andar no mesmo quadro de física.
	process_physics_priority = -1
	profile = PROFILES[clampi(director.difficulty, 0, 2)]
	_turn_rate = profile["turn_rate"]
	_likes_sniper = randf() < profile["sniper_chance"]
	_perception_timer = randf() * PERCEPTION_INTERVAL

	_agent = NavigationAgent3D.new()
	_agent.path_desired_distance = 0.8
	_agent.target_desired_distance = 1.0
	_agent.path_max_distance = 3.0
	_agent.radius = 0.5
	_agent.height = 1.8
	player.add_child.call_deferred(_agent)

	# O Player ainda não rodou o _ready dele: pega a vida pelo caminho.
	(player.get_node("Health") as Health).damaged.connect(_on_damaged)


func team() -> Team.Id:
	return player.health.team


func position() -> Vector3:
	return player.global_position


## true se o bot está livre para atender um aviso de um aliado.
func can_help(at: Vector3, max_distance: float) -> bool:
	if player.health.is_dead or state in [State.COMBATER, State.COBERTURA]:
		return false
	return position().distance_to(at) <= max_distance


## Um aliado viu um inimigo: vai até lá.
func help_teammate(at: Vector3) -> void:
	_start_investigate(at)


func _physics_process(delta: float) -> void:
	if not player.can_act() or not director.nav_ready or not _agent.is_inside_tree():
		_was_dead = _was_dead or player.health.is_dead
		_stop_inputs()
		return
	if _was_dead:
		_was_dead = false
		_on_respawned()

	_perception_timer -= delta
	if _perception_timer <= 0.0:
		_perception_timer = PERCEPTION_INTERVAL
		_perceive()

	player.input_move = Vector2.ZERO
	player.input_sprint = false
	player.input_crouch = false

	match state:
		State.PATRULHAR:
			_update_patrol(delta)
		State.COMBATER:
			_update_combat(delta)
		State.COBERTURA:
			_update_cover(delta)
		State.INVESTIGAR:
			_update_investigate(delta)
		State.SEGUIR:
			_update_follow(delta)

	_manage_weapons(delta)
	_update_look(delta)


func _stop_inputs() -> void:
	player.input_move = Vector2.ZERO
	player.input_sprint = false
	player.input_crouch = false
	player.input_jump = false


func _on_respawned() -> void:
	_target = null
	_visible_enemies.clear()
	_has_look_point = false
	_crouch_spray = false
	_start_patrol(director.choose_lane(self))


# --- Ver e ouvir -------------------------------------------------------------

func _perceive() -> void:
	_visible_enemies.clear()
	var eye := player.camera.global_position
	var forward := -player.global_basis.z
	var half_fov := deg_to_rad(profile["fov_degrees"]) / 2.0
	var heard: Array[Vector3] = []

	for combatant in get_tree().get_nodes_in_group("combatants"):
		var enemy := combatant as Player
		if enemy == null or enemy.health.team == team() or enemy.health.is_dead:
			continue
		var to_enemy := enemy.global_position - player.global_position
		var distance := to_enemy.length()
		if distance <= profile["view_distance"]:
			var flat := Vector3(to_enemy.x, 0.0, to_enemy.z).normalized()
			var in_view := distance < SENSE_DISTANCE or forward.angle_to(flat) <= half_fov
			if in_view and _can_see(eye, enemy):
				_visible_enemies.append(enemy)
				continue
		# Não viu: talvez ouça (tiro, passos correndo) ou veja no minimapa.
		var reveal_left := director.match_mode.reveal_time_left(enemy)
		var just_shot := reveal_left > director.match_mode.reveal_time - 0.3
		if (just_shot and distance < SHOT_HEARING) or reveal_left > 0.0 and distance < 35.0:
			heard.append(enemy.global_position)
		elif distance < FOOTSTEP_HEARING and enemy.ground_speed() > enemy.run_speed * 1.05 and not enemy.is_crouching:
			heard.append(enemy.global_position)

	if not _visible_enemies.is_empty():
		_choose_target()
		return
	if state in [State.PATRULHAR, State.SEGUIR] and not heard.is_empty():
		heard.sort_custom(func(a: Vector3, b: Vector3) -> bool:
			return a.distance_to(position()) < b.distance_to(position()))
		_start_investigate(heard[0])


## Raio de visão: sem parede entre o olho do bot e a cabeça ou o peito do inimigo.
func _can_see(eye: Vector3, enemy: Player) -> bool:
	var space := player.get_world_3d().direct_space_state
	for point in [enemy.head_hitbox.global_position, enemy.global_position + Vector3.UP * 1.0]:
		var query := PhysicsRayQueryParameters3D.create(eye, point, WORLD_MASK)
		if space.intersect_ray(query).is_empty():
			return true
	return false


func _choose_target() -> void:
	if _target != null and _target in _visible_enemies:
		_note_target_seen()
		return
	# O mais perto primeiro; quem já está mirando no bot pesa mais.
	var best: Player = null
	var best_score := INF
	for enemy in _visible_enemies:
		var score := enemy.global_position.distance_to(position())
		var facing := (-enemy.global_basis.z).dot((position() - enemy.global_position).normalized())
		score -= facing * 6.0
		if enemy.health.invulnerable:
			score += 30.0
		if score < best_score:
			best_score = score
			best = enemy
	_acquire(best)


## Viu um alvo novo: tempo de reação, erro de mira inicial e onde mirar.
func _acquire(enemy: Player) -> void:
	var was_alert := state in [State.INVESTIGAR, State.COMBATER] or _now() - _last_seen_time < 2.0
	_target = enemy
	_reaction_timer = profile["reaction"] * randf_range(0.8, 1.3) * (0.7 if was_alert else 1.0)
	_aim_offset = _random_offset(profile["aim_error"] * randf_range(0.7, 1.0))
	_aim_at_head = randf() < profile["head_chance"]
	_engaged_time = 0.0
	_burst_timer = 0.0
	_pause_timer = 0.0
	_crouch_spray = randf() < profile["crouch_chance"]
	_strafe_dir = 1.0 if randf() < 0.5 else -1.0
	_weapon_think_timer = 0.0
	_note_target_seen()
	state = State.COMBATER


func _note_target_seen() -> void:
	_last_seen_position = _target.global_position
	_last_seen_time = _now()
	director.report_enemy(self, _target.global_position)


func _on_damaged(_amount: int, _headshot: bool) -> void:
	if player.health.is_dead or state == State.COMBATER:
		return
	# Levou tiro sem ver de onde: vira para quem atirou por último por perto.
	var best: Player = null
	var best_distance := INF
	for combatant in get_tree().get_nodes_in_group("combatants"):
		var enemy := combatant as Player
		if enemy == null or enemy.health.team == team() or enemy.health.is_dead:
			continue
		if director.match_mode.reveal_time_left(enemy) <= 0.0:
			continue
		var distance := enemy.global_position.distance_to(position())
		if distance < best_distance:
			best_distance = distance
			best = enemy
	if best != null:
		_start_investigate(best.global_position)
		_look_at_point(best.global_position + Vector3.UP * EYE_HEIGHT)


# --- PATRULHAR ---------------------------------------------------------------

func _start_patrol(new_lane: String) -> void:
	state = State.PATRULHAR
	lane = new_lane
	_lane_points = director.lane_points(lane, team()) if not lane.is_empty() else []
	_lane_step = 1
	_lane_index = _closest_lane_index()
	_wait_timer = 0.0
	_stuck_time = 0.0


func _closest_lane_index() -> int:
	var best := 0
	var best_distance := INF
	for i in _lane_points.size():
		var distance := _lane_points[i].distance_to(position())
		if distance < best_distance:
			best_distance = distance
			best = i
	return best


func _update_patrol(delta: float) -> void:
	if director.follow_target(self) != null:
		state = State.SEGUIR
		return
	if _lane_points.is_empty():
		# Mapa sem rotas: anda por pontos sorteados.
		if _goal_timeout <= 0.0 or _flat_distance(position(), _goal) < 1.5:
			_goal = director.random_walkable_point()
			_goal_timeout = 20.0
		_goal_timeout -= delta
		_navigate_to(_goal, true, delta)
		_look_along_path()
		return

	var point := _lane_points[_lane_index]
	if _wait_timer > 0.0:
		# Parado num ponto da rota, olhando as quinas para onde o inimigo pode vir.
		_wait_timer -= delta
		_glance_timer -= delta
		if _glance_timer <= 0.0:
			_glance_timer = randf_range(0.5, 1.2)
			var ahead := _lane_points[clampi(_lane_index + _lane_step, 0, _lane_points.size() - 1)]
			var direction := Vector3(ahead.x - point.x, 0.0, ahead.z - point.z).normalized()
			if direction == Vector3.ZERO:
				direction = -player.global_basis.z
			direction = direction.rotated(Vector3.UP, deg_to_rad(randf_range(-70.0, 70.0)))
			_look_at_point(position() + direction * 10.0 + Vector3.UP * EYE_HEIGHT)
		if _wait_timer <= 0.0:
			_advance_lane()
		return

	if _flat_distance(position(), point) < 1.6:
		_wait_timer = randf_range(0.2, 1.4)
		_glance_timer = 0.0
		return
	# Longe de qualquer inimigo conhecido: corre (Shift). Perto: anda normal.
	var calm := director.recent_intel(team()).all(func(at: Vector3) -> bool: return at.distance_to(position()) > 30.0)
	_navigate_to(point, calm, delta)
	_look_along_path()


func _advance_lane() -> void:
	_lane_index += _lane_step
	if _lane_index >= 0 and _lane_index < _lane_points.size():
		return
	# Chegou no fim da rota: troca de rota (às vezes flanqueia) e volta andando.
	var avoid := director.hot_lane(team()) if randf() < profile["flank_chance"] else lane
	var next_lane := director.choose_lane(self, avoid)
	var step := -_lane_step
	_start_patrol(next_lane)
	_lane_step = step
	_lane_index = _closest_lane_index()


# --- COMBATER ----------------------------------------------------------------

func _update_combat(delta: float) -> void:
	var sees_target := _target != null and is_instance_valid(_target) and _target in _visible_enemies and not _target.health.is_dead
	if not sees_target:
		if _target != null and is_instance_valid(_target) and not _target.health.is_dead and _now() - _last_seen_time < LOST_TARGET_TIME:
			# Acabou de perder de vista: segura a mira onde ele estava.
			_look_at_point(_last_seen_position + Vector3.UP * EYE_HEIGHT)
			return
		_target = null
		if _now() - _last_seen_time < 6.0:
			_start_investigate(_last_seen_position)
		else:
			_start_patrol(lane)
		return

	_engaged_time += delta
	var distance := _target.global_position.distance_to(position())
	var weapons := player.weapons

	# Erro de mira melhora com o tempo (a pessoa "acerta" a mira no alvo).
	var settle := clampf(delta / float(profile["settle_time"]), 0.0, 1.0)
	_aim_offset = _aim_offset.lerp(_random_offset(profile["aim_error_min"]), settle * 2.0)
	var aim_point := _aim_point(_target) + _aim_offset
	_look_at_point(aim_point)

	# Sem bala ou recarregando: cobertura (ou pistola de perto, no _manage_weapons).
	if weapons.is_reloading() and distance > PISTOL_SWITCH_DISTANCE * 0.6:
		if randf() < profile["cover_chance"] * delta * 4.0 and _try_take_cover(_target.global_position):
			return
	if _visible_enemies.size() >= 2 and player.health.current <= 50 and randf() < profile["cover_chance"] * delta:
		if _try_take_cover(_target.global_position):
			return

	_combat_movement(delta, distance)

	if _reaction_timer > 0.0:
		_reaction_timer -= delta
		return
	if _target.health.invulnerable:
		return
	_fire_control(delta, distance, aim_point)


## Ponto do corpo do alvo onde o bot quer acertar (cabeça ou peito).
func _aim_point(enemy: Player) -> Vector3:
	if _aim_at_head:
		return enemy.head_hitbox.global_position
	return enemy.global_position + Vector3.UP * (0.7 if enemy.is_crouching else 1.05)


## Strafe (ADAD), agachar para atirar, chegar perto ou se afastar.
func _combat_movement(delta: float, distance: float) -> void:
	var weapons := player.weapons
	if weapons.is_scoped or (_crouch_spray and _burst_timer > 0.0):
		player.input_crouch = _crouch_spray
		return
	_strafe_timer -= delta
	if _strafe_timer <= 0.0:
		_strafe_timer = randf_range(0.25, 0.7)
		if randf() < profile["strafe_chance"]:
			_strafe_dir = -_strafe_dir if randf() < 0.7 else _strafe_dir
		else:
			_strafe_dir = 0.0
		# De vez em quando pula no meio da troca de lado (só no difícil).
		if director.difficulty == Difficulty.DIFICIL and randf() < 0.05:
			player.input_jump = true

	var right := player.global_basis.x
	var move := right * _strafe_dir
	# Não anda para dentro de parede: se do lado não dá, troca o lado.
	if _strafe_dir != 0.0 and not director.is_walkable(position() + move.normalized() * 1.2):
		_strafe_dir = -_strafe_dir
		move = right * _strafe_dir

	var forward := -player.global_basis.z
	var preferred := 30.0 if weapons.current_index == SNIPER else 14.0
	if distance < 5.0:
		move -= forward * 0.6
	elif distance > preferred + 15.0:
		move += forward * 0.8
	if move.length() > 0.01:
		_set_move_world(move.normalized())


func _fire_control(delta: float, distance: float, aim_point: Vector3) -> void:
	var weapons := player.weapons
	if not weapons.is_ready_to_fire() and weapons.current_index != FUZIL:
		return
	# Só atira com a mira perto do ponto escolhido (tamanho do alvo naquela distância).
	var tolerance := atan2(0.3, maxf(distance, 0.1))
	var aim_direction := -player.camera.global_basis.z
	var wanted := (aim_point - player.camera.global_position).normalized()
	var on_target := aim_direction.angle_to(wanted) <= tolerance

	match weapons.current_index:
		FUZIL:
			if _burst_timer > 0.0:
				_burst_timer -= delta
				if on_target or _burst_timer > 0.05:
					weapons.pull_trigger()
				if _burst_timer <= 0.0:
					_pause_timer = randf_range(profile["burst_pause"].x, profile["burst_pause"].y)
					# De longe, toquinhos curtos; de perto, rajadas mais longas.
					if distance > 25.0:
						_pause_timer += 0.15
			else:
				_pause_timer -= delta
				if _pause_timer <= 0.0 and on_target:
					var burst: Vector2 = profile["burst"]
					_burst_timer = randf_range(burst.x, burst.y) * (0.5 if distance > 25.0 else 1.0)
					weapons.pull_trigger()
		PISTOLA:
			_pause_timer -= delta
			if _pause_timer <= 0.0 and on_target:
				weapons.pull_trigger()
				_pause_timer = randf_range(0.12, 0.3) + profile["burst_pause"].x * 0.5
		SNIPER:
			if not weapons.is_scoped:
				weapons.set_scoped(true)
				return
			# Sniper: espera a mira assentar um pouco mais antes do tiro.
			if on_target and aim_direction.angle_to(wanted) <= tolerance * 0.6:
				weapons.pull_trigger()


## Escolhe a arma pela distância, recarrega fora de combate e volta para o fuzil.
func _manage_weapons(delta: float) -> void:
	var weapons := player.weapons
	_weapon_think_timer -= delta
	var fighting := state == State.COMBATER and _target != null
	if fighting:
		_calm_time = 0.0
	else:
		_calm_time += delta
	if _weapon_think_timer > 0.0:
		return
	_weapon_think_timer = 0.25

	if fighting:
		var distance := _target.global_position.distance_to(position())
		var wanted := FUZIL
		if _likes_sniper and distance > SNIPER_DISTANCE and weapons.ammo_of(SNIPER) > 0:
			wanted = SNIPER
		var rifle_empty := weapons.ammo_of(FUZIL) == 0
		if weapons.current_index == PISTOLA and weapons.ammo_of(PISTOLA) > 0 and distance < PISTOL_SWITCH_DISTANCE * 1.5:
			wanted = PISTOLA
		elif rifle_empty and distance < PISTOL_SWITCH_DISTANCE and weapons.ammo_of(PISTOLA) > 0:
			# Sem bala no fuzil e inimigo perto: sacar a pistola é mais rápido que recarregar.
			wanted = PISTOLA
		if weapons.current_index != wanted and not (weapons.current_index == SNIPER and weapons.is_scoped and wanted == SNIPER):
			weapons.equip(wanted)
		if weapons.current_index != SNIPER and weapons.is_scoped:
			weapons.set_scoped(false)
		if weapons.ammo_in_magazine() == 0 and not weapons.is_reloading():
			weapons.start_reload()
		return

	if weapons.is_scoped:
		weapons.set_scoped(false)
	if _calm_time > 1.0:
		if weapons.current_index != FUZIL:
			weapons.equip(FUZIL)
		elif weapons.ammo_in_magazine() < weapons.current().magazine_size * 0.7 and not weapons.is_reloading():
			weapons.start_reload()


# --- COBERTURA ---------------------------------------------------------------

## Procura um lugar perto, que dá para andar, onde uma parede tapa a visão do inimigo.
func _try_take_cover(threat: Vector3) -> bool:
	var space := player.get_world_3d().direct_space_state
	var threat_eye := threat + Vector3.UP * EYE_HEIGHT
	var my_distance := position().distance_to(threat)
	for radius: float in [2.5, 4.0, 6.0, 8.0]:
		var start := randf() * TAU
		for i in 12:
			var angle := start + TAU * i / 12.0
			var candidate := position() + Vector3(cos(angle), 0.0, sin(angle)) * radius
			if not director.is_walkable(candidate, 0.4):
				continue
			candidate = director.closest_walkable(candidate)
			# Não vai na direção do inimigo.
			if candidate.distance_to(threat) < my_distance - 1.0:
				continue
			var query := PhysicsRayQueryParameters3D.create(candidate + Vector3.UP * EYE_HEIGHT, threat_eye, WORLD_MASK)
			if space.intersect_ray(query).is_empty():
				continue
			_cover_point = candidate
			_cover_threat = threat
			_goal_timeout = 3.5
			_wait_timer = -1.0
			state = State.COBERTURA
			return true
	return false


func _update_cover(delta: float) -> void:
	var weapons := player.weapons
	_look_at_point(_cover_threat + Vector3.UP * EYE_HEIGHT)
	if _wait_timer < 0.0:
		# Indo para a cobertura, correndo.
		_goal_timeout -= delta
		if _flat_distance(position(), _cover_point) < 0.8 or _goal_timeout <= 0.0:
			_wait_timer = randf_range(0.4, 1.0)
		else:
			_navigate_to(_cover_point, true, delta)
		return
	# Atrás da cobertura: agacha e recarrega; depois volta para a briga.
	player.input_crouch = true
	if weapons.ammo_in_magazine() < weapons.current().magazine_size and not weapons.is_reloading():
		weapons.start_reload()
	if weapons.is_reloading():
		return
	_wait_timer -= delta
	if _wait_timer <= 0.0:
		_start_investigate(_last_seen_position if _now() - _last_seen_time < 8.0 else _cover_threat)


# --- INVESTIGAR --------------------------------------------------------------

func _start_investigate(at: Vector3) -> void:
	state = State.INVESTIGAR
	_goal = director.closest_walkable(at)
	_goal_timeout = 15.0
	_wait_timer = -1.0
	_stuck_time = 0.0


func _update_investigate(delta: float) -> void:
	_goal_timeout -= delta
	if _wait_timer >= 0.0:
		# Chegou: olha em volta um pouco e volta a patrulhar.
		_wait_timer -= delta
		_glance_timer -= delta
		if _glance_timer <= 0.0:
			_glance_timer = randf_range(0.4, 0.9)
			var direction := Vector3.FORWARD.rotated(Vector3.UP, randf() * TAU)
			_look_at_point(position() + direction * 10.0 + Vector3.UP * EYE_HEIGHT)
		if _wait_timer < 0.0:
			_start_patrol(lane)
		return
	var distance := _flat_distance(position(), _goal)
	if distance < 1.8 or _goal_timeout <= 0.0:
		_wait_timer = randf_range(1.0, 2.5)
		_glance_timer = 0.0
		return
	_navigate_to(_goal, distance > 25.0, delta)
	# Já mira (pre-aim) para o lugar onde acha que o inimigo está.
	if distance < 25.0:
		_look_at_point(_goal + Vector3.UP * EYE_HEIGHT)
	else:
		_look_along_path()


# --- SEGUIR ------------------------------------------------------------------

func _update_follow(delta: float) -> void:
	var leader := director.follow_target(self)
	if leader == null:
		_start_patrol(lane)
		return
	var behind := leader.global_position + leader.global_basis.z * 3.0 + leader.global_basis.x * 1.5
	var spot := director.closest_walkable(behind)
	if _flat_distance(position(), spot) > 2.5:
		_navigate_to(spot, _flat_distance(position(), spot) > 10.0, delta)
		_look_along_path()
	else:
		# Perto do líder: olha para o mesmo lado que ele, cobrindo um pouco para o lado.
		var direction := (-leader.global_basis.z).rotated(Vector3.UP, deg_to_rad(35.0))
		_look_at_point(position() + direction * 10.0 + Vector3.UP * EYE_HEIGHT)


# --- Andar e mirar -----------------------------------------------------------

## Anda até "point" pela malha de navegação. Se ficar preso, pula e desvia.
func _navigate_to(point: Vector3, sprint: bool, delta: float) -> void:
	if _agent.target_position.distance_to(point) > 0.5:
		_agent.target_position = point
	if _agent.is_navigation_finished():
		return
	var next := _agent.get_next_path_position()
	var direction := Vector3(next.x - position().x, 0.0, next.z - position().z)
	if direction.length() < 0.05:
		return
	direction = direction.normalized() + _separation()

	if _unstuck_timer > 0.0:
		_unstuck_timer -= delta
		direction = _unstuck_dir
	elif player.ground_speed() < STUCK_SPEED:
		_stuck_time += delta
		if _stuck_time > 0.5:
			_stuck_time = 0.0
			player.input_jump = true
			_unstuck_dir = direction.normalized().rotated(Vector3.UP, deg_to_rad(90.0 if randf() < 0.5 else -90.0))
			_unstuck_timer = 0.35
	else:
		_stuck_time = 0.0

	_set_move_world(direction.normalized())
	player.input_sprint = sprint


## Empurrãozinho para longe de aliados muito perto (não andam grudados).
func _separation() -> Vector3:
	var push := Vector3.ZERO
	for combatant in get_tree().get_nodes_in_group("combatants"):
		var other := combatant as Player
		if other == null or other == player or other.health.is_dead or other.health.team != team():
			continue
		var away := position() - other.global_position
		away.y = 0.0
		var distance := away.length()
		if distance > 0.01 and distance < 1.6:
			push += away / distance * (1.6 - distance) * 0.8
	return push


## Converte uma direção do mundo em "teclas" (WASD) relativas para onde o bot olha.
func _set_move_world(direction: Vector3) -> void:
	var local := player.global_basis.inverse() * direction
	player.input_move = Vector2(local.x, local.z).limit_length(1.0)


func _look_along_path() -> void:
	if _agent.is_navigation_finished():
		return
	var next := _agent.get_next_path_position()
	var direction := Vector3(next.x - position().x, 0.0, next.z - position().z)
	if direction.length() > 0.3:
		_look_at_point(position() + direction.normalized() * 10.0 + Vector3.UP * EYE_HEIGHT)


func _look_at_point(point: Vector3) -> void:
	_look_point = point
	_has_look_point = true


## Gira a câmera em direção ao ponto escolhido, rápido no começo e devagar no fim
## (como uma pessoa movendo o mouse), com velocidade máxima.
func _update_look(delta: float) -> void:
	if not _has_look_point:
		return
	var from := player.camera.global_position
	var to := _look_point - from
	if to.length() < 0.05:
		return
	var wanted_yaw := atan2(-to.x, -to.z)
	var wanted_pitch := atan2(to.y, Vector2(to.x, to.z).length())
	var step := 1.0 - exp(-_turn_rate * delta)
	var max_step := deg_to_rad(720.0) * delta
	var yaw_diff := wrapf(wanted_yaw - player.rotation.y, -PI, PI)
	player.rotation.y += clampf(yaw_diff * step, -max_step, max_step)
	var pitch_diff := wanted_pitch - player.look_pitch
	player.look_pitch = clampf(player.look_pitch + clampf(pitch_diff * step, -max_step, max_step), deg_to_rad(-89.0), deg_to_rad(89.0))
	player.camera.rotation.x = player.look_pitch


# --- Ajudantes ---------------------------------------------------------------

## Erro de mira: um ponto aleatório numa bolinha de "size" metros.
static func _random_offset(size: float) -> Vector3:
	var direction := Vector3(randf_range(-1.0, 1.0), randf_range(-0.6, 0.6), randf_range(-1.0, 1.0))
	return direction.normalized() * size * sqrt(randf()) if direction.length() > 0.01 else Vector3.ZERO


static func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


static func _now() -> float:
	return Time.get_ticks_msec() / 1000.0
