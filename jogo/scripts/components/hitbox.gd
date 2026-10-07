class_name Hitbox
extends Area3D
## Uma parte do corpo que pode ser atingida por tiro.
## Marque "is_head" na hitbox da cabeça.
## A hitbox procura sozinha o nó "Health" na raiz da cena (o boneco).

const LAYER := 4 # camada 3 "hitbox" (valor em bits: 1, 2, 4...)

@export var is_head := false
@export var health: Health


func _ready() -> void:
	if health == null:
		health = owner.get_node_or_null("Health") as Health


## Liga/desliga a hitbox (por exemplo quando o boneco morre).
func set_enabled(enabled: bool) -> void:
	collision_layer = LAYER if enabled else 0
