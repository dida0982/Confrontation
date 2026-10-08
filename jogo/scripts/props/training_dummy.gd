extends StaticBody3D
## Boneco de treino: leva tiro, mostra a vida, morre e volta depois de um tempo.
## Usa o mesmo corpo 3D dos jogadores (CharacterModel), com contorno na cor do time.
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
## Só para testar o minimapa: finge que atira a cada X segundos (clarão no
## cano e aparece no minimapa, mas não causa dano). 0 = desligado.
@export var simulate_shot_interval := 0.0

var _start_position: Vector3
var _time := 0.0
var _flash_timer := 0.0
var _shot_timer := 0.0

@onready var health: Health = $Health
@onready var model: CharacterModel = $Visual
@onready var label: Label3D = $HealthLabel
@onready var hitboxes: Node3D = $Hitboxes


func _ready() -> void:
	add_to_group("training_dummy")
	_start_position = position
	model.set_team_color(Team.color_of(health.team))
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	_update_label()


func _process(delta: float) -> void:
	if health.is_dead:
		return

	var local_velocity := Vector3.ZERO
	if strafe_distance > 0.0:
		var before := pingpong(_time * strafe_speed, strafe_distance * 2.0)
		_time += delta
		var now := pingpong(_time * strafe_speed, strafe_distance * 2.0)
		position = _start_position + transform.basis.x * (now - strafe_distance)
		local_velocity = Vector3((now - before) / maxf(delta, 0.0001), 0, 0)
	model.update_movement(local_velocity, false)

	if simulate_shot_interval > 0.0:
		_shot_timer += delta
		if _shot_timer >= simulate_shot_interval:
			_shot_timer = 0.0
			MuzzleFlash.spawn(get_tree().current_scene, model.muzzle_position())
			shot_fired.emit()

	# Pisca o contorno quando leva tiro, depois volta para a cor do time.
	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			model.set_team_color(Team.color_of(health.team))


func _on_damaged(_amount: int, headshot: bool) -> void:
	_flash_timer = 0.12
	model.set_team_color(Color.YELLOW if headshot else Color.WHITE)
	_update_label()


func _on_died(_killer: Node, _headshot: bool) -> void:
	label.visible = false
	for hitbox in hitboxes.get_children():
		(hitbox as Hitbox).set_enabled(false)
	model.play_death()
	await get_tree().create_timer(respawn_time).timeout
	health.reset()
	_update_label()
	model.reset()
	model.set_team_color(Team.color_of(health.team))
	label.visible = true
	for hitbox in hitboxes.get_children():
		(hitbox as Hitbox).set_enabled(true)


func _update_label() -> void:
	label.text = str(health.current)
