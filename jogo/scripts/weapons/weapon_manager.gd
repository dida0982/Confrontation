class_name WeaponManager
extends Node3D
## Controla as armas do jogador: trocar, atirar, recarregar, mirar com zoom.
##
## O tiro é "hitscan": um raio invisível sai do centro da câmera em linha reta
## e acerta na hora. Por isso a bala não cai e não demora para chegar.
## As armas não têm recuo: a mira não sobe nem abre ao atirar sem parar.
##
## Os nós filhos (modelos das armas) precisam estar na MESMA ORDEM da lista "weapons".
## Cada modelo tem um nó "Cano" (Marker3D) onde aparece o clarão do tiro.

signal hit_confirmed(headshot: bool, killed: bool)
## Disparou um tiro (usado para revelar o atirador no minimapa).
signal fired

## Bits das camadas que o tiro acerta: 1 = mundo, 4 = hitbox.
## (Não acerta a camada 2 "jogadores", que é só para colisão de movimento.)
const SHOT_MASK := 1 | 4
const KICK_DISTANCE := 0.05
const MAX_IMPACT_MARKS := 60

@export var weapons: Array[WeaponData] = [
	preload("res://weapons/fuzil.tres"),
	preload("res://weapons/pistola.tres"),
	preload("res://weapons/sniper.tres"),
]
@export var impact_mark_lifetime := 10.0
## Som de tiro de cada arma (mesma ordem da lista "weapons").
@export var shot_sounds: Array[AudioStream] = [
	preload("res://sons/tiro_fuzil.wav"),
	preload("res://sons/tiro_pistola.wav"),
	preload("res://sons/tiro_sniper.wav"),
]

var current_index := -1
var is_scoped := false

var _magazine: Array[int] = []
var _fire_cooldown := 0.0
var _reload_timer := 0.0
var _equip_timer := 0.0
var _fire_blocked := false
var _default_fov := 90.0
var _rest_position := Vector3.ZERO
var _kick := 0.0
var _impact_marks: Array[Node3D] = []
var _impact_mesh: SphereMesh
var _shot_player: AudioStreamPlayer
var _foley_player: AudioStreamPlayer

const RELOAD_START_SOUND := preload("res://sons/recarga_1.ogg")
const RELOAD_END_SOUND := preload("res://sons/recarga_2.ogg")
const EQUIP_SOUND := preload("res://sons/trocar_arma.ogg")

@onready var player: Player = owner as Player
@onready var camera: Camera3D = get_parent() as Camera3D


func _ready() -> void:
	_default_fov = camera.fov
	_rest_position = position
	for weapon in weapons:
		_magazine.append(weapon.magazine_size)

	_impact_mesh = SphereMesh.new()
	_impact_mesh.radius = 0.03
	_impact_mesh.height = 0.06
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.05, 0.05, 0.05)
	_impact_mesh.material = material

	# Modelos das armas em primeira pessoa não fazem sombra no chão.
	for mesh in find_children("*", "MeshInstance3D", true, false):
		(mesh as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	_shot_player = _new_audio_player(6)
	_foley_player = _new_audio_player(2)
	equip(0)


func current() -> WeaponData:
	return weapons[current_index]


func ammo_in_magazine() -> int:
	return _magazine[current_index]


func is_reloading() -> bool:
	return _reload_timer > 0.0


## Evita que o clique usado para "prender" o mouse na tela dispare um tiro.
func block_fire_until_release() -> void:
	_fire_blocked = true


## Enche todos os pentes e volta para o fuzil (usado ao renascer).
func refill() -> void:
	for i in weapons.size():
		_magazine[i] = weapons[i].magazine_size
	set_scoped(false)
	_reload_timer = 0.0
	_fire_cooldown = 0.0
	current_index = -1
	equip(0)
	_equip_timer = 0.0


func equip(index: int) -> void:
	if index == current_index or index < 0 or index >= weapons.size():
		return
	set_scoped(false)
	_reload_timer = 0.0
	current_index = index
	# Só os primeiros filhos são armas (depois vêm os tocadores de som).
	for i in weapons.size():
		(get_child(i) as Node3D).visible = i == index
	_equip_timer = current().equip_time
	_play_foley(EQUIP_SOUND, -8.0)


func get_speed_multiplier() -> float:
	if current_index < 0:
		return 1.0
	var weapon := current()
	return weapon.move_speed_multiplier * (weapon.scoped_speed_multiplier if is_scoped else 1.0)


## Imprecisão atual em graus. Não muda com o movimento: andar, correr,
## pular ou deslizar não atrapalham o tiro. Só a sniper sem zoom é imprecisa.
func current_spread_deg() -> float:
	var weapon := current()
	return weapon.scoped_spread if is_scoped else weapon.base_spread


func set_scoped(value: bool) -> void:
	if is_scoped == value:
		return
	is_scoped = value
	camera.fov = current().scope_fov if value else _default_fov
	visible = not value
	# Com zoom o mouse fica mais lento, para a mira não ficar "pulando".
	player.sensitivity_scale = current().scope_fov / _default_fov if value else 1.0


func start_reload() -> void:
	var weapon := current()
	if is_reloading() or _magazine[current_index] >= weapon.magazine_size:
		return
	set_scoped(false)
	_reload_timer = weapon.reload_time
	_play_foley(RELOAD_START_SOUND, -6.0)


func _process(delta: float) -> void:
	_fire_cooldown = maxf(_fire_cooldown - delta, 0.0)
	_equip_timer = maxf(_equip_timer - delta, 0.0)

	_kick = move_toward(_kick, 0.0, 0.5 * delta)
	position = _rest_position + Vector3(0, 0, _kick)

	if is_reloading():
		_reload_timer -= delta
		if _reload_timer <= 0.0:
			_finish_reload()

	if _fire_blocked:
		if Input.is_action_pressed("fire"):
			return
		_fire_blocked = false
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED or not player.can_act():
		return

	if Input.is_action_just_pressed("reload"):
		start_reload()
	if Input.is_action_just_pressed("aim") and current().has_scope and not is_reloading() and _equip_timer <= 0.0:
		set_scoped(not is_scoped)

	var wants_fire := Input.is_action_pressed("fire") if current().automatic else Input.is_action_just_pressed("fire")
	if wants_fire:
		_try_fire()


func _unhandled_input(event: InputEvent) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED or not player.can_act():
		return
	if event.is_action_pressed("weapon_1"):
		equip(0)
	elif event.is_action_pressed("weapon_2"):
		equip(1)
	elif event.is_action_pressed("weapon_3"):
		equip(2)
	elif event.is_action_pressed("weapon_next"):
		equip(wrapi(current_index + 1, 0, weapons.size()))
	elif event.is_action_pressed("weapon_prev"):
		equip(wrapi(current_index - 1, 0, weapons.size()))


func _try_fire() -> void:
	if _fire_cooldown > 0.0 or _equip_timer > 0.0 or is_reloading():
		return
	if _magazine[current_index] <= 0:
		start_reload()
		return

	var weapon := current()
	_magazine[current_index] -= 1
	_fire_cooldown = weapon.fire_interval
	_shoot_ray(weapon)
	fired.emit()
	_play_shot_effects()
	_kick = KICK_DISTANCE
	# Atirar cancela a proteção de nascimento.
	player.health.invulnerable = false

	if _magazine[current_index] == 0:
		start_reload()


func _shoot_ray(weapon: WeaponData) -> void:
	# Direção: centro da mira + um desvio aleatório dentro do "cone" de imprecisão.
	var cam_basis := camera.global_basis
	var radius := tan(deg_to_rad(current_spread_deg())) * sqrt(randf())
	var angle := randf() * TAU
	var direction := (-cam_basis.z + cam_basis.x * cos(angle) * radius + cam_basis.y * sin(angle) * radius).normalized()

	var from := camera.global_position
	var query := PhysicsRayQueryParameters3D.create(from, from + direction * weapon.max_range, SHOT_MASK)
	query.collide_with_areas = true
	query.exclude = player.get_own_rids()
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return

	var hitbox := hit.collider as Hitbox
	if hitbox != null and hitbox.health != null:
		# Sem fogo amigo: tiro em aliado não causa dano.
		if hitbox.health.team == player.health.team or hitbox.health.is_dead:
			return
		# Mostra o acerto na hora e pede para o servidor (host) conferir e aplicar o dano.
		hit_confirmed.emit(hitbox.is_head, false)
		var match_mode := get_tree().get_first_node_in_group("match") as TeamDeathmatch
		if match_mode != null:
			match_mode.report_hit(hitbox.owner, hitbox.is_head, current_index, from)
	else:
		_spawn_impact_mark(hit.position, hit.normal)


func _spawn_impact_mark(hit_position: Vector3, normal: Vector3) -> void:
	var mark := MeshInstance3D.new()
	mark.mesh = _impact_mesh
	mark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	get_tree().current_scene.add_child(mark)
	mark.global_position = hit_position + normal * 0.005
	_impact_marks.append(mark)
	if _impact_marks.size() > MAX_IMPACT_MARKS:
		var oldest: Node3D = _impact_marks.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()
	get_tree().create_timer(impact_mark_lifetime).timeout.connect(func() -> void:
		if is_instance_valid(mark):
			_impact_marks.erase(mark)
			mark.queue_free()
	)


func _finish_reload() -> void:
	_reload_timer = 0.0
	_play_foley(RELOAD_END_SOUND, -4.0)
	_magazine[current_index] = current().magazine_size


func _play_shot_effects() -> void:
	if current_index < shot_sounds.size():
		_shot_player.stream = shot_sounds[current_index]
		_shot_player.pitch_scale = randf_range(0.96, 1.04)
		_shot_player.play()
	var muzzle := get_child(current_index).get_node_or_null("Cano") as Node3D
	if muzzle != null and visible:
		MuzzleFlash.spawn(get_tree().current_scene, muzzle.global_position)


func _play_foley(sound: AudioStream, volume_db: float) -> void:
	if _foley_player == null or not player.is_local():
		return
	_foley_player.stream = sound
	_foley_player.volume_db = volume_db
	_foley_player.play()


func _new_audio_player(polyphony: int) -> AudioStreamPlayer:
	var audio := AudioStreamPlayer.new()
	audio.bus = GameSettings.EFFECTS_BUS
	audio.max_polyphony = polyphony
	add_child(audio)
	return audio
