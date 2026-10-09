extends SceneTree
## Lança os testes automáticos do Confrontation sem abrir janela:
##
##   Godot_v4.7.2-stable_win64_console.exe --headless --path jogo -s res://testes/rodar_testes.gd
##
## Os testes ficam em testes/testes.gd. Cada um imprime OK ou FALHOU e o
## programa sai com o número de falhas (0 = tudo certo).
## Para rodar só alguns, passe os nomes depois de "--":  ... -- dano bots_por_time
##
## (Este arquivo só carrega o testes.gd depois que os autoloads, como "Rede",
## já existem; um script de SceneTree é compilado antes deles.)


func _initialize() -> void:
	root.add_child.call_deferred((load("res://testes/testes.gd") as GDScript).new())
