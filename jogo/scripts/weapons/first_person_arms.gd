class_name FirstPersonArms
extends Node3D
## Braços em primeira pessoa (manga do uniforme + luva), montados com formas
## simples. Cada braço vai de um "cotovelo" fixo perto da câmera até a mão, que
## fica presa num marcador da arma ("MaoDireita" e "MaoEsquerda"). Assim, quando
## a arma mexe (tiro, troca, recarga), as mãos acompanham.
##
## Na recarga, a mão esquerda vai até o pente, desce para fora da tela, volta
## com um pente novo e encaixa (segue reload_progress() do WeaponManager).

const SLEEVE_COLOR := Color(0.13, 0.15, 0.21)
const GLOVE_COLOR := Color(0.07, 0.07, 0.08)
const MAGAZINE_COLOR := Color(0.12, 0.12, 0.13)
## Cotovelos, em relação à câmera (x = direita, y = cima, z = para trás).
const RIGHT_ELBOW := Vector3(0.3, -0.4, 0.04)
const LEFT_ELBOW := Vector3(-0.02, -0.42, -0.18)
## Para onde a mão esquerda vai buscar o pente novo (fora da tela).
const LEFT_HAND_AWAY := Vector3(0.08, -0.5, -0.25)
const FOREARM_RADIUS := 0.042

@export var weapon_manager: WeaponManager

var _right_forearm: MeshInstance3D
var _right_hand: MeshInstance3D
var _left_forearm: MeshInstance3D
var _left_hand: MeshInstance3D
var _new_magazine: MeshInstance3D

@onready var _camera: Camera3D = get_parent() as Camera3D


func _ready() -> void:
	_right_forearm = _new_part(_forearm_mesh(), SLEEVE_COLOR)
	_right_hand = _new_part(_hand_mesh(), GLOVE_COLOR)
	_left_forearm = _new_part(_forearm_mesh(), SLEEVE_COLOR)
	_left_hand = _new_part(_hand_mesh(), GLOVE_COLOR)
	var magazine := BoxMesh.new()
	magazine.size = Vector3(0.03, 0.12, 0.06)
	_new_magazine = _new_part(magazine, MAGAZINE_COLOR)


func _process(_delta: float) -> void:
	# Some junto com a arma: com zoom da sniper, morto ou no boneco dos outros.
	visible = weapon_manager != null and weapon_manager.visible and weapon_manager.current_index >= 0
	if not visible:
		return
	var weapon := weapon_manager.current_weapon_node()
	var grip := weapon.get_node("MaoDireita") as Node3D
	var support := weapon.get_node("MaoEsquerda") as Node3D
	var magwell := weapon.get_node("Pente") as Node3D

	_place_arm(_right_forearm, _right_hand, _camera.to_global(RIGHT_ELBOW), grip.global_transform)

	var left_target := support.global_transform
	var progress := weapon_manager.reload_progress()
	_new_magazine.visible = false
	if progress >= 0.0:
		left_target = _left_hand_during_reload(progress, support.global_transform, magwell.global_transform)
	_place_arm(_left_forearm, _left_hand, _camera.to_global(LEFT_ELBOW), left_target)


## Caminho da mão esquerda na recarga (0 = começo, 1 = fim).
func _left_hand_during_reload(progress: float, support: Transform3D, magwell: Transform3D) -> Transform3D:
	var away := Transform3D(magwell.basis, _camera.to_global(LEFT_HAND_AWAY))
	var mag_in := WeaponManager.RELOAD_MAG_IN
	var target: Transform3D
	if progress < 0.15:
		target = support
	elif progress < 0.3:
		target = support.interpolate_with(magwell, smoothstep(0.15, 0.3, progress))
	elif progress < 0.45:
		target = magwell.interpolate_with(away, smoothstep(0.3, 0.45, progress))
	elif progress < mag_in:
		target = away.interpolate_with(magwell, smoothstep(0.45, mag_in, progress))
		_show_magazine(target)
	elif progress < 0.75:
		target = magwell
	else:
		target = magwell.interpolate_with(support, smoothstep(0.75, 0.9, progress))
	return target


func _show_magazine(hand: Transform3D) -> void:
	_new_magazine.visible = true
	_new_magazine.global_transform = Transform3D(hand.basis, hand.origin + hand.basis.y * 0.07)


## Coloca o antebraço entre o cotovelo e a mão, e a luva na mão.
func _place_arm(forearm: MeshInstance3D, hand: MeshInstance3D, elbow: Vector3, wrist: Transform3D) -> void:
	hand.global_transform = wrist
	var to_wrist := wrist.origin - elbow
	var length := to_wrist.length()
	if length < 0.001:
		return
	var direction := to_wrist / length
	var basis := Basis(Quaternion(Vector3.UP, direction)).scaled(Vector3(1, length, 1))
	forearm.global_transform = Transform3D(basis, elbow + to_wrist * 0.5)


func _forearm_mesh() -> Mesh:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = FOREARM_RADIUS * 0.85
	cylinder.bottom_radius = FOREARM_RADIUS
	cylinder.height = 1.0
	cylinder.radial_segments = 10
	return cylinder


func _hand_mesh() -> Mesh:
	var box := BoxMesh.new()
	box.size = Vector3(0.06, 0.07, 0.09)
	return box


func _new_part(mesh: Mesh, color: Color) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.85
	part.material_override = material
	add_child(part)
	return part
