class_name WeaponData
extends Resource
## Todos os números de uma arma. Cada arma é um arquivo .tres na pasta "weapons".
## Dê dois cliques no arquivo .tres no Godot para mudar os valores no Inspetor.

@export var display_name := "Arma"
## true = segura o botão para atirar sem parar. false = um tiro por clique.
@export var automatic := false
## Segundos entre um tiro e outro.
@export var fire_interval := 0.15
@export var magazine_size := 12
@export var reserve_ammo := 36
@export var reload_time := 1.75
## Tempo para sacar a arma depois de trocar.
@export var equip_time := 0.5
@export var max_range := 300.0

@export_group("Dano")
@export var head_damage := 100
@export var body_damage := 25

@export_group("Precisão (em graus)")
## Imprecisão parado. 0 = tiro perfeito no centro da mira.
@export var base_spread := 0.3
## Imprecisão extra correndo (andando com Shift é bem menos).
@export var move_spread := 3.0
## Imprecisão extra no ar (pulando).
@export var air_spread := 6.0
## Quanto a imprecisão cresce a cada tiro seguido (spray).
@export var spray_spread_per_shot := 0.0
@export var max_spray_spread := 0.0
## Segundos sem atirar para a mira voltar ao normal.
@export var spray_reset_time := 0.35

@export_group("Recuo")
## Graus que a mira sobe a cada tiro.
@export var recoil_kick := 0.0
@export var max_recoil := 0.0

@export_group("Mira com zoom")
@export var has_scope := false
## Campo de visão com zoom (menor = mais zoom).
@export var scope_fov := 40.0
@export var scoped_spread := 0.0

@export_group("Movimento")
## Velocidade do jogador segurando esta arma (1 = normal).
@export var move_speed_multiplier := 1.0
@export var scoped_speed_multiplier := 1.0
