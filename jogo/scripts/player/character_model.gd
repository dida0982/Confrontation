class_name CharacterModel
extends Node3D
## Corpo 3D que os OUTROS jogadores veem (modelo SWAT do Quaternius, CC0).
## - anima conforme o movimento: parado, correndo para frente/trás/lados;
## - segura a arma atual na mão direita;
## - tem um contorno na cor do time (como o contorno dos inimigos no Valorant);
## - cai quando morre.

const ANIM_IDLE := "CharacterArmature|Idle_Gun_Pointing"
const ANIM_FORWARD := "CharacterArmature|Run_Shoot"
const ANIM_BACK := "CharacterArmature|Run_Back"
const ANIM_LEFT := "CharacterArmature|Run_Left"
const ANIM_RIGHT := "CharacterArmature|Run_Right"
const ANIM_DEATH := "CharacterArmature|Death"
const LOOPING := [ANIM_IDLE, ANIM_FORWARD, ANIM_BACK, ANIM_LEFT, ANIM_RIGHT]
const BLEND_TIME := 0.15
const HAND_BONE := "Wrist.R"
const WEAPON_SCENES := [
	preload("res://scenes/armas/fuzil.tscn"),
	preload("res://scenes/armas/pistola.tscn"),
	preload("res://scenes/armas/sniper.tscn"),
]
const OUTLINE_SIZE := 0.012

## Rotação e posição das armas na mão (ajustadas olhando o modelo).
@export var weapon_rotation_degrees := Vector3(90, -90, 0)
@export var weapon_offset := Vector3(0.0, 0.0, 0.0)

var _weapons: Array[Node3D] = []
var _dead := false

@onready var _animation: AnimationPlayer = find_children("*", "AnimationPlayer", true, false)[0]
@onready var _skeleton: Skeleton3D = find_children("*", "Skeleton3D", true, false)[0]


func _ready() -> void:
	for anim_name in LOOPING:
		_animation.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR
	var hand := BoneAttachment3D.new()
	hand.bone_name = HAND_BONE
	_skeleton.add_child(hand)
	for scene in WEAPON_SCENES:
		var weapon := (scene as PackedScene).instantiate() as Node3D
		hand.add_child(weapon)
		# Compensa a escala do osso (o modelo é feito em outra escala por dentro).
		var bone_scale := hand.global_transform.basis.get_scale().x
		weapon.transform = Transform3D(Basis.from_euler(weapon_rotation_degrees * PI / 180.0).scaled(Vector3.ONE / maxf(bone_scale, 0.0001)), weapon_offset / maxf(bone_scale, 0.0001))
		_weapons.append(weapon)
	set_weapon(0)
	_animation.play(ANIM_IDLE)


## Contorno colorido em volta do corpo (azul ou vermelho).
func set_team_color(color: Color) -> void:
	for node in find_children("*", "MeshInstance3D", true, false):
		if _is_weapon_part(node):
			continue
		var mesh := node as MeshInstance3D
		var outline := StandardMaterial3D.new()
		outline.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		outline.cull_mode = BaseMaterial3D.CULL_FRONT
		outline.grow = true
		# O contorno é medido nas unidades da malha, que pode estar em outra escala.
		outline.grow_amount = OUTLINE_SIZE / maxf(mesh.global_transform.basis.get_scale().x, 0.0001)
		outline.albedo_color = color
		mesh.material_overlay = outline


func set_weapon(index: int) -> void:
	for i in _weapons.size():
		_weapons[i].visible = i == index


## Escolhe a animação pela velocidade, vista do ponto de vista do personagem.
func update_movement(local_velocity: Vector3, crouching: bool) -> void:
	if _dead:
		return
	scale.y = 0.78 if crouching else 1.0
	var flat := Vector2(local_velocity.x, local_velocity.z)
	var speed := flat.length()
	var target := ANIM_IDLE
	if speed > 0.4:
		if absf(flat.y) >= absf(flat.x):
			target = ANIM_FORWARD if flat.y < 0.0 else ANIM_BACK
		else:
			target = ANIM_RIGHT if flat.x > 0.0 else ANIM_LEFT
	_animation.speed_scale = clampf(speed / 5.5, 0.6, 1.4) if target != ANIM_IDLE else 1.0
	if _animation.current_animation != target:
		_animation.play(target, BLEND_TIME)


func play_death() -> void:
	_dead = true
	scale.y = 1.0
	_animation.speed_scale = 1.0
	_animation.play(ANIM_DEATH, 0.1)


func reset() -> void:
	_dead = false
	_animation.play(ANIM_IDLE, 0.0)


## Posição do cano da arma que está na mão (para o clarão do tiro).
func muzzle_position() -> Vector3:
	for weapon in _weapons:
		if weapon.visible:
			return (weapon.get_node("Cano") as Node3D).global_position
	return global_position + Vector3.UP * 1.4


func _is_weapon_part(node: Node) -> bool:
	for weapon in _weapons:
		if weapon.is_ancestor_of(node):
			return true
	return false
