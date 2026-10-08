extends StaticBody3D
## Boneco de treino: leva tiro, mostra a vida, morre e volta depois de um tempo.
## Pode ficar parado ou andar de um lado para o outro (strafe).
## Por padrão é do time Vermelho, então cada abate conta ponto para o Azul.

## Atirou (ou fingiu atirar): aparece no minimapa por alguns segundos.
signal shot_fired

## Nome que aparece no feed de abates.
@export var display_name := "Boneco"
@export var respawn_time := 2.0
## Distância que ele anda para cada lado. 0 = fica parado.
@export var strafe_distance := 0.0
@export var strafe_speed := 3.0
@export var base_color := Color(0.85, 0.35, 0.25)
## Só para testar o minimapa: finge que atira a cada X segundos (pisca
## laranja e aparece no minimapa, mas não causa dano). 0 = desligado.
@export var simulate_shot_interval := 0.0

var _start_position: Vector3
var _time := 0.0
var _flash_timer := 0.0
var _flash_color := Color.WHITE
var _shot_timer := 0.0
var _material := StandardMaterial3D.new()

@onready var health: Health = $Health
@onready var visual: Node3D = $Visual
@onready var label: Label3D = $HealthLabel
@onready var hitboxes: Node3D = $Hitboxes


func _ready() -> void:
	_start_position = position
	_material.albedo_color = base_color
	for mesh in visual.get_children():
		(mesh as MeshInstance3D).material_override = _material
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	_update_label()


func _process(delta: float) -> void:
	if strafe_distance > 0.0 and not health.is_dead:
		_time += delta
		var offset := pingpong(_time * strafe_speed, strafe_distance * 2.0) - strafe_distance
		position = _start_position + transform.basis.x * offset

	if simulate_shot_interval > 0.0 and not health.is_dead:
		_shot_timer += delta
		if _shot_timer >= simulate_shot_interval:
			_shot_timer = 0.0
			_flash_timer = 0.1
			_flash_color = Color.ORANGE
			shot_fired.emit()

	if _flash_timer > 0.0:
		_flash_timer -= delta
		_material.albedo_color = _flash_color if _flash_timer > 0.0 else base_color


func _on_damaged(_amount: int, headshot: bool) -> void:
	_flash_timer = 0.12
	_flash_color = Color.YELLOW if headshot else Color.WHITE
	_update_label()


func _on_died(_killer: Node, _headshot: bool) -> void:
	_set_alive(false)
	await get_tree().create_timer(respawn_time).timeout
	health.reset()
	_update_label()
	_set_alive(true)


func _set_alive(alive: bool) -> void:
	visual.visible = alive
	label.visible = alive
	for hitbox in hitboxes.get_children():
		(hitbox as Hitbox).set_enabled(alive)


func _update_label() -> void:
	label.text = str(health.current)
