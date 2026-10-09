class_name Player
extends CharacterBody3D
## Jogador em primeira pessoa: câmera no mouse, andar, correr (Shift),
## agachar, pular e deslizar (Ctrl com velocidade alta).
## As armas ficam no nó WeaponManager (filho da câmera).
##
## Em rede, cada jogador existe em todos os computadores:
## - no computador do DONO (is_local() == true) ele lê teclado e mouse, usa a
##   câmera e manda a posição para os outros (variáveis net_*, copiadas pelo
##   nó SyncMovimento);
## - nos outros computadores ele mostra o corpo 3D animado (CharacterModel),
##   com contorno na cor do time, e segue as variáveis net_* com suavização.
##
## Bots: o bot é este mesmo jogador, mas com is_bot = true. Ele é simulado no
## host (servidor) e quem aperta as "teclas" é o cérebro BotController, pelas
## variáveis input_*. Para os outros computadores ele é um jogador normal.
##
## Sons: passos (silencioso agachado ou deslizando), pulo, aterrissagem e
## deslize e, nos outros computadores, o tiro de quem atirou (a arma local toca
## o próprio som no WeaponManager).

const STAND_HEIGHT := 1.8
const CROUCH_HEIGHT := 1.2
const CAPSULE_RADIUS := 0.4
const BODY_HITBOX_STAND := 1.44
const BODY_HITBOX_CROUCH := 0.95
const DEAD_HEAD_HEIGHT := 0.3
## Quão rápido o boneco dos outros jogadores alcança a posição recebida.
const REMOTE_SMOOTHING := 18.0
## Se a posição recebida estiver mais longe que isso, teleporta (ex.: renasceu).
const REMOTE_TELEPORT_DISTANCE := 4.0
## Metros andados entre um passo e outro.
const STEP_DISTANCE := 2.0
const FOOTSTEP_SOUNDS := [
	preload("res://sons/passo_0.ogg"), preload("res://sons/passo_1.ogg"), preload("res://sons/passo_2.ogg"),
	preload("res://sons/passo_3.ogg"), preload("res://sons/passo_4.ogg"),
]
const JUMP_SOUND := preload("res://sons/pulo.ogg")
const LAND_SOUND := preload("res://sons/aterrissagem.ogg")
const SLIDE_SOUND := preload("res://sons/deslize.wav")
## Velocidade de queda (m/s) a partir da qual a aterrissagem faz barulho.
const LAND_SOUND_MIN_SPEED := 4.0
const SHOT_SOUNDS := [
	preload("res://sons/tiro_fuzil.wav"), preload("res://sons/tiro_pistola.wav"), preload("res://sons/tiro_sniper.wav"),
]

## Atirou (a partida usa isso para revelar o jogador no minimapa dos inimigos).
signal shot_fired

## Nome que aparece no feed de abates.
@export var display_name := "Você"
## true = controlado pelo computador (BotController), não por uma pessoa.
var is_bot := false

@export_group("Movimento (metros por segundo)")
## Velocidade normal (só com WASD).
@export var run_speed := 5.5
## Velocidade segurando Shift (correr mais rápido).
@export var sprint_speed := 7.5
@export var crouch_speed := 2.0
@export var ground_accel := 50.0
## Frear rápido ao soltar a tecla, como no Valorant (ajuda a parar e atirar).
@export var ground_decel := 60.0
@export var air_accel := 6.0
@export var jump_velocity := 4.6

@export_group("Deslize")
## Velocidade mínima para o Ctrl virar deslize (correndo com Shift passa disso).
@export var slide_min_speed := 6.0
## Velocidade extra ganha ao começar a deslizar.
@export var slide_boost := 2.0
@export var slide_max_speed := 10.0
## Quanto o deslize perde de velocidade por segundo.
@export var slide_friction := 7.0
## Abaixo desta velocidade o deslize acaba e vira agachado normal.
@export var slide_end_speed := 3.0
## Tempo depois de um deslize até poder deslizar de novo.
@export var slide_cooldown := 0.6
## Inclinação da câmera durante o deslize (graus).
@export var slide_camera_tilt := 5.0

@export_group("Câmera")
@export var stand_head_height := 1.6
@export var crouch_head_height := 1.1
@export var crouch_transition_speed := 8.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
## Olhar para cima/baixo controlado pelo mouse.
var look_pitch := 0.0
## Multiplicador da sensibilidade (fica menor com a mira da sniper).
var sensitivity_scale := 1.0
var is_crouching := false
var is_sliding := false
## Desligado pela partida quando ela termina.
var controls_enabled := true
## Proteção de nascimento para aplicar quando o jogador aparece (a partida define).
var spawn_protection_on_ready := 0.0

# Comandos de movimento deste quadro. No jogador humano vêm do teclado
# (_read_keyboard); no bot, o BotController preenche.
## Direção pedida: x = direita, y = para trás (como Input.get_vector).
var input_move := Vector2.ZERO
var input_sprint := false
var input_crouch := false
## Pulo pedido neste quadro (é consumido ao pular).
var input_jump := false
var _crouch_was_pressed := false

# Copiadas do dono para os outros computadores pelo nó SyncMovimento.
var net_position := Vector3.ZERO
var net_yaw := 0.0
var net_crouching := false
var net_weapon := 0
# Contadores de pulo, aterrissagem e deslize: quando mudam, os outros tocam o som.
var net_jumps := 0
var net_landings := 0
var net_slides := 0

var _heard_jumps := 0
var _heard_landings := 0
var _heard_slides := 0
## Tremor da câmera (0 a 1), por exemplo num TRIPLE KILL.
var _shake := 0.0

var _step_distance := 0.0
## Velocidade estimada dos outros jogadores (para animação e passos).
var _remote_velocity := Vector3.ZERO

var _spawn_protection_timer := 0.0
var _slide_direction := Vector3.ZERO
var _slide_speed := 0.0
var _slide_cooldown_timer := 0.0
## Apertou Ctrl no ar com velocidade: desliza ao tocar o chão.
var _slide_queued := false

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var weapons: WeaponManager = $Head/Camera3D/WeaponManager
@onready var health: Health = $Health
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var hitboxes: Node3D = $Hitboxes
@onready var head_hitbox: Hitbox = $Hitboxes/Head
@onready var body_hitbox: Hitbox = $Hitboxes/Body
@onready var body_visual: CharacterModel = $Corpo
@onready var footsteps: AudioStreamPlayer3D = $Passos
@onready var shot_audio: AudioStreamPlayer3D = $SomTiro
@onready var movement_audio: AudioStreamPlayer3D = $SomMovimento
@onready var speaking_label: Label3D = $FalandoLabel


func _ready() -> void:
	health.died.connect(_on_died)
	weapons.fired.connect(shot_fired.emit)
	net_position = global_position
	net_yaw = rotation.y

	body_visual.set_team_color(Team.color_of(health.team))
	var steps := AudioStreamRandomizer.new()
	for sound in FOOTSTEP_SOUNDS:
		steps.add_stream(-1, sound)
	steps.random_pitch = 1.1
	footsteps.stream = steps

	if is_local():
		add_to_group("player")
		camera.make_current()
		body_visual.visible = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		camera.current = false
		weapons.visible = false
		weapons.set_process_unhandled_input(false)
		set_process_unhandled_input(false)
		# O bot (no host) usa as armas de verdade: precisa dos tempos de tiro e recarga.
		weapons.set_process(is_simulated_here())

	_heard_jumps = net_jumps
	_heard_landings = net_landings
	_heard_slides = net_slides

	if spawn_protection_on_ready > 0.0:
		health.invulnerable = true
		_spawn_protection_timer = spawn_protection_on_ready


## true no computador da PESSOA que controla este jogador (nunca para bots).
func is_local() -> bool:
	return is_multiplayer_authority() and not is_bot


## true no computador que calcula o movimento deste jogador: o da pessoa
## que joga com ele ou, no caso de um bot, o host.
func is_simulated_here() -> bool:
	return is_multiplayer_authority()


## true se o jogador está vivo e pode se mexer e atirar
## (falso com o menu aberto, porque o mouse fica solto).
func can_act() -> bool:
	if not controls_enabled or health.is_dead:
		return false
	return is_bot or Input.mouse_mode == Input.MOUSE_MODE_CAPTURED


## Velocidade no chão (m/s), também para jogadores de outros computadores.
## Os bots usam para "ouvir" passos de quem está correndo.
func ground_speed() -> float:
	var moving := velocity if is_simulated_here() else _remote_velocity
	return Vector2(moving.x, moving.z).length()


## Coloca o jogador vivo no ponto de nascimento, com vida e pentes cheios.
## Fica sem levar dano por "protection_time" segundos ou até atirar.
func respawn(at: Transform3D, protection_time: float) -> void:
	health.reset()
	global_position = at.origin
	rotation = Vector3(0.0, at.basis.get_euler().y, 0.0)
	net_position = global_position
	net_yaw = rotation.y
	velocity = Vector3.ZERO
	look_pitch = 0.0
	is_sliding = false
	_slide_queued = false
	if is_crouching:
		_set_crouch(false)
	head.position.y = stand_head_height
	collision_layer = 2
	for hitbox in hitboxes.get_children():
		(hitbox as Hitbox).set_enabled(true)
	weapons.refill()
	weapons.visible = is_local()
	body_visual.visible = not is_local()
	body_visual.reset()
	health.invulnerable = protection_time > 0.0
	_spawn_protection_timer = protection_time


func _on_died(_killer: Node, _headshot: bool) -> void:
	weapons.set_scoped(false)
	weapons.visible = false
	# Os outros veem o corpo cair; ele some quando renasce.
	if not is_local():
		body_visual.play_death()
	health.invulnerable = false
	# Corpo morto não bloqueia ninguém nem leva tiro.
	collision_layer = 0
	for hitbox in hitboxes.get_children():
		(hitbox as Hitbox).set_enabled(false)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var motion := event as InputEventMouseMotion
		# A sensibilidade é ajustada no menu (Esc > Mira).
		var sensitivity := Configuracoes.radians_per_pixel() * sensitivity_scale
		rotate_y(-motion.relative.x * sensitivity)
		look_pitch = clampf(look_pitch - motion.relative.y * sensitivity, deg_to_rad(-89.0), deg_to_rad(89.0))
	elif event.is_action_pressed("debug_kill") and OS.is_debug_build() and can_act():
		# Só para testes: morrer na hora para testar o renascimento.
		var match_mode := get_tree().get_first_node_in_group("match") as TeamDeathmatch
		if match_mode != null:
			match_mode.request_suicide()
	elif event is InputEventMouseButton and event.is_pressed() and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		# Clicar na tela prende o mouse de novo (ex.: depois de trocar de janela).
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		weapons.block_fire_until_release()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if is_bot:
		# A mira do bot é a câmera (invisível): o tiro sai dela.
		camera.rotation.x = look_pitch
		return
	if not is_local():
		# Aviso "FALANDO" em cima de quem está usando o chat de voz perto de você.
		speaking_label.visible = not health.is_dead and not is_bot and Voz.is_speaking(name.to_int())
		return
	camera.rotation.x = look_pitch
	if _shake > 0.0:
		_shake = move_toward(_shake, 0.0, delta * 2.0)
		camera.h_offset = randf_range(-1.0, 1.0) * _shake * 0.035
		camera.v_offset = randf_range(-1.0, 1.0) * _shake * 0.035
	var target_tilt := deg_to_rad(slide_camera_tilt) if is_sliding else 0.0
	camera.rotation.z = lerpf(camera.rotation.z, target_tilt, minf(10.0 * delta, 1.0))


func _physics_process(delta: float) -> void:
	if _spawn_protection_timer > 0.0:
		_spawn_protection_timer -= delta
		if _spawn_protection_timer <= 0.0:
			health.invulnerable = false

	if not is_simulated_here():
		_follow_network(delta)
		return

	var active := can_act()
	if not is_bot:
		_read_keyboard(active)
	elif not active:
		input_move = Vector2.ZERO
		input_jump = false
	_slide_cooldown_timer = maxf(_slide_cooldown_timer - delta, 0.0)
	if active:
		_update_slide_start()

	if health.is_dead:
		# Câmera desce até o chão enquanto espera renascer.
		head.position.y = move_toward(head.position.y, DEAD_HEAD_HEIGHT, 3.0 * delta)
	else:
		_update_crouch(delta)

	if not is_on_floor():
		velocity.y -= gravity * delta
	elif active and input_jump:
		velocity.y = jump_velocity
		net_jumps += 1
		_play_movement_sound(JUMP_SOUND, -4.0)
		# Pular no meio do deslize mantém o embalo.
		_end_slide()

	input_jump = false
	var input_dir := input_move.limit_length(1.0) if active else Vector2.ZERO
	var wish_dir := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)

	if is_sliding:
		_slide_speed = move_toward(_slide_speed, 0.0, slide_friction * delta)
		horizontal = _slide_direction * _slide_speed
	elif is_on_floor():
		var accel := ground_accel if wish_dir != Vector3.ZERO else ground_decel
		horizontal = horizontal.move_toward(wish_dir * _max_speed(), accel * delta)
	elif wish_dir != Vector3.ZERO:
		# No ar dá para corrigir um pouco a direção, mas não muito.
		# Não perde o embalo que já tinha (ex.: pulo no meio do deslize).
		var air_speed := maxf(_max_speed(), horizontal.length())
		horizontal = horizontal.move_toward(wish_dir * air_speed, air_accel * delta)

	velocity.x = horizontal.x
	velocity.z = horizontal.z
	var was_on_floor := is_on_floor()
	var fall_speed := -velocity.y
	move_and_slide()
	if not was_on_floor and is_on_floor() and fall_speed > LAND_SOUND_MIN_SPEED:
		net_landings += 1
		_play_movement_sound(LAND_SOUND, clampf(-12.0 + fall_speed, -8.0, 2.0))

	if is_sliding:
		_update_slide_after_move()

	net_position = global_position
	net_yaw = rotation.y
	net_crouching = is_crouching
	net_weapon = weapons.current_index
	_update_footsteps(_horizontal_speed(), is_on_floor() and not is_sliding, delta)
	if is_bot:
		# No host, o corpo do bot é animado aqui (nos outros, por _follow_network).
		body_visual.set_weapon(weapons.current_index)
		body_visual.update_movement(global_basis.inverse() * velocity, is_crouching)


## Jogador humano: lê o teclado (sem controle com o menu aberto ou morto).
func _read_keyboard(active: bool) -> void:
	if not active:
		input_move = Vector2.ZERO
		input_sprint = false
		input_crouch = false
		input_jump = false
		return
	input_move = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	input_sprint = Input.is_action_pressed("sprint")
	input_crouch = Input.is_action_pressed("crouch")
	input_jump = Input.is_action_just_pressed("jump")


## Faz a câmera tremer um pouco (não mexe na mira).
func shake(strength: float) -> void:
	_shake = maxf(_shake, strength)


## Pulo, aterrissagem e deslize (os próprios soam mais baixo).
func _play_movement_sound(sound: AudioStream, volume_db: float) -> void:
	movement_audio.stream = sound
	movement_audio.volume_db = volume_db - (6.0 if is_local() else 0.0)
	movement_audio.pitch_scale = randf_range(0.94, 1.06)
	movement_audio.play()


## Nos outros computadores: toca os sons de movimento quando os contadores mudam.
func _play_remote_movement_sounds() -> void:
	if net_jumps != _heard_jumps:
		_heard_jumps = net_jumps
		_play_movement_sound(JUMP_SOUND, -4.0)
	if net_landings != _heard_landings:
		_heard_landings = net_landings
		_play_movement_sound(LAND_SOUND, -2.0)
	if net_slides != _heard_slides:
		_heard_slides = net_slides
		_play_movement_sound(SLIDE_SOUND, 0.0)


## Nos outros computadores: toca o tiro desta arma e o clarão no cano.
func play_remote_shot(weapon_index: int) -> void:
	if weapon_index < 0 or weapon_index >= SHOT_SOUNDS.size():
		return
	shot_audio.global_position = body_visual.muzzle_position()
	shot_audio.stream = SHOT_SOUNDS[weapon_index]
	shot_audio.pitch_scale = randf_range(0.96, 1.04)
	shot_audio.play()
	MuzzleFlash.spawn(get_tree().current_scene, body_visual.muzzle_position())


## Passo a cada STEP_DISTANCE metros. Agachado não faz barulho (como andar no Valorant).
func _update_footsteps(speed: float, on_ground: bool, delta: float) -> void:
	if not on_ground or is_crouching or speed < 1.0 or health.is_dead:
		return
	_step_distance += speed * delta
	if _step_distance < STEP_DISTANCE:
		return
	_step_distance = 0.0
	# Os próprios passos soam mais baixo; correndo com Shift soa mais alto.
	footsteps.volume_db = (2.0 if speed > run_speed * 1.1 else -2.0) - (8.0 if is_local() else 0.0)
	footsteps.play()


## Nos outros computadores: segue a posição que o dono mandou, suavizando.
func _follow_network(delta: float) -> void:
	var before := global_position
	if global_position.distance_to(net_position) > REMOTE_TELEPORT_DISTANCE:
		global_position = net_position
		before = global_position
	else:
		global_position = global_position.lerp(net_position, minf(REMOTE_SMOOTHING * delta, 1.0))
	rotation.y = lerp_angle(rotation.y, net_yaw, minf(REMOTE_SMOOTHING * delta, 1.0))
	if health.is_dead:
		return
	_play_remote_movement_sounds()
	_remote_velocity = _remote_velocity.lerp((global_position - before) / maxf(delta, 0.0001), minf(10.0 * delta, 1.0))
	var flat_speed := Vector2(_remote_velocity.x, _remote_velocity.z).length()
	body_visual.set_weapon(net_weapon)
	body_visual.update_movement(global_basis.inverse() * _remote_velocity, net_crouching)
	_update_footsteps(flat_speed, absf(_remote_velocity.y) < 0.8, delta)
	if net_crouching != is_crouching:
		_set_crouch(net_crouching)
	var target_height := crouch_head_height if is_crouching else stand_head_height
	head.position.y = move_toward(head.position.y, target_height, crouch_transition_speed * delta)
	_update_head_parts()


## RIDs do próprio jogador, para o tiro não acertar a si mesmo.
func get_own_rids() -> Array[RID]:
	var rids: Array[RID] = [get_rid()]
	for hitbox in hitboxes.get_children():
		rids.append((hitbox as CollisionObject3D).get_rid())
	return rids


func _max_speed() -> float:
	var speed := run_speed
	if is_crouching:
		speed = crouch_speed
	elif input_sprint:
		speed = sprint_speed
	return speed * weapons.get_speed_multiplier()


func _horizontal_speed() -> float:
	return Vector2(velocity.x, velocity.z).length()


## Começa o deslize quando aperta Ctrl rápido o bastante (no chão, ou ao
## aterrissar se apertou no ar depois de pular correndo).
func _update_slide_start() -> void:
	var crouch_just_pressed := input_crouch and not _crouch_was_pressed
	_crouch_was_pressed = input_crouch
	if is_sliding:
		return
	if crouch_just_pressed and _horizontal_speed() >= slide_min_speed and _slide_cooldown_timer <= 0.0:
		if is_on_floor():
			_start_slide()
		else:
			_slide_queued = true
	if _slide_queued:
		if not input_crouch:
			_slide_queued = false
		elif is_on_floor():
			_slide_queued = false
			if _horizontal_speed() >= slide_min_speed:
				_start_slide()


func _start_slide() -> void:
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	is_sliding = true
	_slide_direction = horizontal.normalized()
	_slide_speed = minf(horizontal.length() + slide_boost, slide_max_speed)
	net_slides += 1
	_play_movement_sound(SLIDE_SOUND, 0.0)
	if not is_crouching:
		_set_crouch(true)


func _end_slide() -> void:
	if not is_sliding:
		return
	is_sliding = false
	_slide_cooldown_timer = slide_cooldown


func _update_slide_after_move() -> void:
	# Se bateu numa parede, o deslize perde velocidade e acompanha a parede.
	var real_speed := _horizontal_speed()
	_slide_speed = minf(_slide_speed, real_speed)
	if real_speed > 0.1:
		_slide_direction = Vector3(velocity.x, 0.0, velocity.z) / real_speed
	if _slide_speed <= slide_end_speed or not is_on_floor() or not input_crouch or not can_act():
		_end_slide()


func _update_crouch(delta: float) -> void:
	var wants_crouch := input_crouch or is_sliding
	if wants_crouch and not is_crouching:
		_set_crouch(true)
	elif not wants_crouch and is_crouching and _can_stand_up():
		_set_crouch(false)

	var target_height := crouch_head_height if is_crouching else stand_head_height
	head.position.y = move_toward(head.position.y, target_height, crouch_transition_speed * delta)
	_update_head_parts()


## Hitbox e modelo da cabeça acompanham a altura da cabeça (agachar).
func _update_head_parts() -> void:
	head_hitbox.position.y = head.position.y + 0.05


func _set_crouch(value: bool) -> void:
	is_crouching = value
	var height := CROUCH_HEIGHT if value else STAND_HEIGHT
	var capsule := collision_shape.shape as CapsuleShape3D
	capsule.height = height
	collision_shape.position.y = height / 2.0

	var body_height := BODY_HITBOX_CROUCH if value else BODY_HITBOX_STAND
	var body_shape := (body_hitbox.get_node("CollisionShape3D") as CollisionShape3D).shape as CapsuleShape3D
	body_shape.height = body_height
	body_hitbox.position.y = body_height / 2.0


## Confere se tem espaço acima da cabeça para levantar.
func _can_stand_up() -> bool:
	var shape := CapsuleShape3D.new()
	shape.radius = CAPSULE_RADIUS - 0.05
	shape.height = STAND_HEIGHT - 0.1
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = global_transform.translated(Vector3(0.0, STAND_HEIGHT / 2.0 + 0.05, 0.0))
	query.collision_mask = collision_mask
	query.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()
