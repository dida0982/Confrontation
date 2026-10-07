class_name Crosshair
## Desenha a mira no centro de um Control. Usado pelo HUD e pela prévia no menu.

const COLOR := Color(0.35, 1.0, 0.65)
const OUTLINE_COLOR := Color.BLACK

const CROSS_GAP := 4.0
const CROSS_LENGTH := 7.0
const CROSS_THICKNESS := 2.0
const DOT_SIZE := 4.0


static func draw(canvas: CanvasItem, center: Vector2, style: GameSettings.CrosshairStyle) -> void:
	match style:
		GameSettings.CrosshairStyle.PONTO:
			_draw_dot(canvas, center)
		GameSettings.CrosshairStyle.CRUZ:
			_draw_cross(canvas, center)


static func _draw_dot(canvas: CanvasItem, center: Vector2) -> void:
	var half := DOT_SIZE / 2.0
	canvas.draw_rect(Rect2(center - Vector2(half + 1.0, half + 1.0), Vector2(DOT_SIZE + 2.0, DOT_SIZE + 2.0)), OUTLINE_COLOR)
	canvas.draw_rect(Rect2(center - Vector2(half, half), Vector2(DOT_SIZE, DOT_SIZE)), COLOR)


static func _draw_cross(canvas: CanvasItem, center: Vector2) -> void:
	for dir in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
		var start: Vector2 = center + dir * CROSS_GAP
		var end: Vector2 = center + dir * (CROSS_GAP + CROSS_LENGTH)
		# Contorno preto um pouco maior por baixo, para enxergar em fundo claro.
		canvas.draw_line(start - dir, end + dir, OUTLINE_COLOR, CROSS_THICKNESS + 2.0)
		canvas.draw_line(start, end, COLOR, CROSS_THICKNESS)
