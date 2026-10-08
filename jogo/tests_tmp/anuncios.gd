extends SceneTree
const OUT := "C:/Users/dida0/AppData/Local/Temp/claude/c--Users-dida0-jogo-de-fps/7735e43c-97c7-4f0e-8484-4945f854ccd9/scratchpad"
func _initialize() -> void:
	_run.call_deferred()
func _shot(n: String) -> void:
	root.get_viewport().get_texture().get_image().save_png(OUT + "/" + n + ".png")
func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.get_node("Rede").play_offline("Teste", "res://scenes/sala_de_treino.tscn")
	await create_timer(0.6).timeout
	_shot("an_0_fight")
	await create_timer(2.5).timeout
	var m = current_scene.get_node("TeamDeathmatch")
	var p = m.local_player
	var a = current_scene.get_node("HUD")._announcer
	var dummies = get_nodes_in_group("training_dummy")
	m._apply_damage(dummies[0], 100, true, p)
	await create_timer(0.12).timeout
	_shot("an_1_headshot_pop")
	print("1: ", a._title.text, " | ", a._subtitle.text)
	await create_timer(0.6).timeout
	m._apply_damage(dummies[1], 100, false, p)
	await create_timer(0.35).timeout
	_shot("an_2_double")
	print("2: ", a._title.text, " | ", a._subtitle.text)
	await create_timer(0.5).timeout
	m._apply_damage(dummies[2], 100, true, p)
	await create_timer(0.08).timeout
	_shot("an_3_triple_inicio")
	await create_timer(0.4).timeout
	_shot("an_3_triple")
	print("3: ", a._title.text, " | ", a._subtitle.text, " tremor=", p._shake)
	await create_timer(5.0).timeout
	m._apply_damage(dummies[3], 100, false, p)
	await create_timer(0.1).timeout
	print("4 (depois de 5 s): ", a._title.text, " | ", a._subtitle.text, " visível=", a._banner.visible)
	await create_timer(5.0).timeout
	m._apply_damage(dummies[4], 100, false, p)
	await create_timer(0.4).timeout
	_shot("an_5_sequencia")
	print("5: ", a._title.text, " | ", a._subtitle.text)
	quit()
