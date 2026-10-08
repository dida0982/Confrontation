class_name Crosshair
## Desenha a mira no centro de um Control. Usado pelo HUD e pela prévia nas
## configurações. Cor, tamanho, espessura, espaço e contorno vêm de Configuracoes.

const OUTLINE_COLOR := Color.BLACK

## Cores prontas para escolher nas configurações (nome -> cor).
const COLORS := {
	"Verde": Color(0.35, 1.0, 0.65),
	"Branco": Color(1, 1, 1),
	"Amarelo": Color(1.0, 0.95, 0.2),
	"Ciano": Color(0.2, 0.95, 1.0),
	"Rosa": Color(1.0, 0.35, 0.85),
	"Vermelho": Color(1.0, 0.25, 0.25),
}


static func draw(canvas: CanvasItem, center: Vector2) -> void:
	var settings := canvas.get_node("/root/Configuracoes") as GameSettings
	match settings.crosshair_style:
		GameSettings.CrosshairStyle.PONTO:
			_draw_dot(canvas, center, settings)
		GameSettings.CrosshairStyle.CRUZ:
			_draw_cross(canvas, center, settings)


static func _draw_dot(canvas: CanvasItem, center: Vector2, settings: GameSettings) -> void:
	var size := maxf(settings.crosshair_size * 0.6, 2.0)
	var half := size / 2.0
	if settings.crosshair_outline:
		canvas.draw_rect(Rect2(center - Vector2(half + 1.0, half + 1.0), Vector2(size + 2.0, size + 2.0)), OUTLINE_COLOR)
	canvas.draw_rect(Rect2(center - Vector2(half, half), Vector2(size, size)), settings.crosshair_color)


static func _draw_cross(canvas: CanvasItem, center: Vector2, settings: GameSettings) -> void:
	var gap := settings.crosshair_gap
	var length := settings.crosshair_size
	var thickness := settings.crosshair_thickness
	for dir in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
		var start: Vector2 = center + dir * gap
		var end: Vector2 = center + dir * (gap + length)
		if settings.crosshair_outline:
			# Contorno preto um pouco maior por baixo, para enxergar em fundo claro.
			canvas.draw_line(start - dir, end + dir, OUTLINE_COLOR, thickness + 2.0)
		canvas.draw_line(start, end, settings.crosshair_color, thickness)
