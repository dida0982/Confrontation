class_name Player
extends CharacterBody3D
## Jogador em primeira pessoa: câmera no mouse, andar, correr (Shift),
## agachar e pular. As armas ficam no nó WeaponManager (filho da câmera).

const STAND_HEIGHT := 1.8
const CROUCH_HEIGHT := 1.2
const CAPSULE_RADIUS := 0.4
const BODY_HITBOX_STAND := 1.44
const BODY_HITBOX_CROUCH := 0.95
const DEAD_HEAD_HEIGHT := 0.3

## Nome que aparece no feed de abates.
@export var display_name := "Você"

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

@export_group("Câmera")
## Sensibilidade do mouse (radianos por pixel).
@export var mouse_sensitivity := 0.0025
@export var stand_head_height := 1.6
@export var crouch_head_height := 1.1
@export var crouch_transition_speed := 8.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
## Olhar para cima/baixo controlado pelo mouse.
var look_pitch := 0.0
## Multiplicador da sensibilidade (fica menor com a mira da sniper).
var sensitivity_scale := 1.0
var is_crouching := false
## Desligado pela partida quando ela termina.
var controls_enabled := true

var _spawn_protection_timer := 0.0

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var weapons: WeaponManager = $Head/Camera3D/WeaponManager
@onready var health: Health = $Health
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var hitboxes: Node3D = $Hitboxes
@onready var head_hitbox: Hitbox = $Hitboxes/Head
@onready var body_hitbox: Hitbox = $Hitboxes/Body


func _ready() -> void:
	add_to_group("player")
	health.died.connect(_on_died)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


## true se o jogador está vivo e pode se mexer e atirar.
func can_act() -> bool:
	return controls_enabled and not health.is_dead


## Coloca o jogador vivo no ponto de nascimento, com vida e pentes cheios.
## Fica sem levar dano por "protection_time" segundos ou até atirar.
func respawn(at: Transform3D, protection_time: float) -> void:
	health.reset()
	global_position = at.origin
	rotation = Vector3(0.0, at.basis.get_euler().y, 0.0)
	velocity = Vector3.ZERO
	look_pitch = 0.0
	if is_crouching:
		_set_crouch(false)
	head.position.y = stand_head_height
	collision_layer = 2
	for hitbox in hitboxes.get_children():
		(hitbox as Hitbox).set_enabled(true)
	weapons.refill()
	weapons.visible = true
	health.invulnerable = protection_time > 0.0
	_spawn_protection_timer = protection_time


func _on_died(_killer: Node, _headshot: bool) -> void:
	weapons.set_scoped(false)
	weapons.visible = false
	health.invulnerable = false
	# Corpo morto não bloqueia ninguém nem leva tiro.
	collision_layer = 0
	for hitbox in hitboxes.get_children():
		(hitbox as Hitbox).set_enabled(false)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var motion := event as InputEventMouseMotion
		var sensitivity := mouse_sensitivity * sensitivity_scale
		rotate_y(-motion.relative.x * sensitivity)
		look_pitch = clampf(look_pitch - motion.relative.y * sensitivity, deg_to_rad(-89.0), deg_to_rad(89.0))
	elif event.is_action_pressed("ui_cancel"):
		# Esc solta o mouse.
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event.is_action_pressed("debug_kill") and OS.is_debug_build() and can_act():
		# Só para testes: morrer na hora para testar o renascimento.
		health.invulnerable = false
		health.take_damage(health.max_health, false)
	elif event is InputEventMouseButton and event.is_pressed() and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		# Clicar na tela prende o mouse de novo.
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		weapons.block_fire_until_release()
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	camera.rotation.x = look_pitch


func _physics_process(delta: float) -> void:
	if _spawn_protection_timer > 0.0:
		_spawn_protection_timer -= delta
		if _spawn_protection_timer <= 0.0:
			health.invulnerable = false

	if health.is_dead:
		# Câmera desce até o chão enquanto espera renascer.
		head.position.y = move_toward(head.position.y, DEAD_HEAD_HEIGHT, 3.0 * delta)
	else:
		_update_crouch(delta)

	var active := can_act()
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif active and Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back") if active else Vector2.ZERO
	var wish_dir := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)

	if is_on_floor():
		var accel := ground_accel if wish_dir != Vector3.ZERO else ground_decel
		horizontal = horizontal.move_toward(wish_dir * _max_speed(), accel * delta)
	elif wish_dir != Vector3.ZERO:
		# No ar dá para corrigir um pouco a direção, mas não muito.
		horizontal = horizontal.move_toward(wish_dir * _max_speed(), air_accel * delta)

	velocity.x = horizontal.x
	velocity.z = horizontal.z
	move_and_slide()


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
	elif Input.is_action_pressed("sprint"):
		speed = sprint_speed
	return speed * weapons.get_speed_multiplier()


func _update_crouch(delta: float) -> void:
	var wants_crouch := Input.is_action_pressed("crouch")
	if wants_crouch and not is_crouching:
		_set_crouch(true)
	elif not wants_crouch and is_crouching and _can_stand_up():
		_set_crouch(false)

	var target_height := crouch_head_height if is_crouching else stand_head_height
	head.position.y = move_toward(head.position.y, target_height, crouch_transition_speed * delta)
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
