class_name Health
extends Node
## Vida de qualquer coisa que pode levar tiro (jogador, boneco de treino).

signal damaged(amount: int, headshot: bool)
signal died

@export var max_health: int = 100

var current: int
var is_dead := false


func _ready() -> void:
	current = max_health


## Aplica dano. Retorna true se esse tiro matou.
func take_damage(amount: int, headshot: bool) -> bool:
	if is_dead:
		return false
	current = maxi(current - amount, 0)
	damaged.emit(amount, headshot)
	if current == 0:
		is_dead = true
		died.emit()
	return is_dead


func reset() -> void:
	current = max_health
	is_dead = false
