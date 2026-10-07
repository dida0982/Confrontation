class_name Health
extends Node
## Vida de qualquer coisa que pode levar tiro (jogador, boneco de treino).
## Também guarda o time, para o jogo saber quem é aliado e quem é inimigo.

signal damaged(amount: int, headshot: bool)
## killer é quem deu o tiro final (null se morreu sozinho).
signal died(killer: Node, headshot: bool)

@export var max_health: int = 100
@export var team: Team.Id = Team.Id.AZUL

var current: int
var is_dead := false
## Proteção de nascimento: enquanto true, não leva dano.
var invulnerable := false


func _ready() -> void:
	current = max_health


## Aplica dano. Retorna true se esse tiro matou.
func take_damage(amount: int, headshot: bool, attacker: Node = null) -> bool:
	if is_dead or invulnerable:
		return false
	current = maxi(current - amount, 0)
	damaged.emit(amount, headshot)
	if current == 0:
		is_dead = true
		died.emit(attacker, headshot)
	return is_dead


func reset() -> void:
	current = max_health
	is_dead = false
