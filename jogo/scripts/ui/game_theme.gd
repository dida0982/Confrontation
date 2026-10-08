class_name GameTheme
## Visual de todos os menus e textos do jogo (fonte, botões, barras, painéis).
## É aplicado uma vez quando o jogo abre (no autoload Controles), mudando o tema
## padrão do Godot. Assim todo Button, Label, Slider etc. já nasce com esse visual.

const BACKGROUND := Color(0.06, 0.09, 0.13)
const PANEL := Color(0.08, 0.11, 0.16, 0.96)
const ACCENT := Color(1.0, 0.28, 0.33)
const ACCENT_DARK := Color(0.78, 0.18, 0.23)
const TEXT := Color(0.93, 0.91, 0.88)
const TEXT_DIM := Color(0.93, 0.91, 0.88, 0.55)
const FIELD := Color(1, 1, 1, 0.06)
const FIELD_HOVER := Color(1, 1, 1, 0.12)

const FONT := preload("res://fontes/Rajdhani-SemiBold.ttf")
const FONT_BOLD := preload("res://fontes/Rajdhani-Bold.ttf")


static func apply() -> void:
	var theme := ThemeDB.get_default_theme()
	var font := _with_fallback(FONT)
	theme.default_font = font
	theme.default_font_size = 20
	ThemeDB.fallback_font = font

	for type in ["Label", "Button", "LineEdit", "OptionButton", "CheckBox", "CheckButton", "SpinBox", "PopupMenu", "TabBar", "RichTextLabel"]:
		theme.set_color("font_color", type, TEXT)

	# Botões: retângulo escuro; passando o mouse fica vermelho.
	for type in ["Button", "OptionButton"]:
		theme.set_stylebox("normal", type, _box(FIELD))
		theme.set_stylebox("hover", type, _box(ACCENT))
		theme.set_stylebox("pressed", type, _box(ACCENT_DARK))
		theme.set_stylebox("hover_pressed", type, _box(ACCENT))
		theme.set_stylebox("disabled", type, _box(Color(1, 1, 1, 0.03)))
		theme.set_stylebox("focus", type, StyleBoxEmpty.new())
		theme.set_color("font_hover_color", type, Color.WHITE)
		theme.set_color("font_pressed_color", type, Color.WHITE)
		theme.set_color("font_hover_pressed_color", type, Color.WHITE)
		theme.set_color("font_disabled_color", type, TEXT_DIM)

	# Botões que ficam "marcados" (ex.: Ponto/Cruz): marcado = vermelho.
	theme.set_stylebox("pressed", "Button", _box(ACCENT_DARK))

	theme.set_stylebox("normal", "LineEdit", _box(FIELD, 2, ACCENT))
	theme.set_stylebox("focus", "LineEdit", _box(FIELD_HOVER, 2, ACCENT))
	theme.set_stylebox("read_only", "LineEdit", _box(FIELD))

	theme.set_stylebox("panel", "PanelContainer", _box(PANEL, 0, Color.TRANSPARENT, 4, 24))
	theme.set_stylebox("panel", "PopupMenu", _box(PANEL, 0, Color.TRANSPARENT, 2, 8))
	theme.set_stylebox("hover", "PopupMenu", _box(ACCENT))

	# Barras deslizantes e de progresso.
	var track := _box(Color(1, 1, 1, 0.15))
	track.content_margin_top = 3
	track.content_margin_bottom = 3
	theme.set_stylebox("slider", "HSlider", track)
	theme.set_stylebox("grabber_area", "HSlider", _box(ACCENT))
	theme.set_stylebox("grabber_area_highlight", "HSlider", _box(ACCENT))
	theme.set_stylebox("background", "ProgressBar", _box(Color(1, 1, 1, 0.1)))
	theme.set_stylebox("fill", "ProgressBar", _box(ACCENT))

	# Abas das configurações.
	theme.set_stylebox("tab_selected", "TabContainer", _box(ACCENT, 0, Color.TRANSPARENT, 2, 10))
	theme.set_stylebox("tab_unselected", "TabContainer", _box(FIELD, 0, Color.TRANSPARENT, 2, 10))
	theme.set_stylebox("tab_hovered", "TabContainer", _box(FIELD_HOVER, 0, Color.TRANSPARENT, 2, 10))
	theme.set_stylebox("panel", "TabContainer", _box(Color(0, 0, 0, 0.2), 0, Color.TRANSPARENT, 2, 16))
	theme.set_color("font_selected_color", "TabContainer", Color.WHITE)
	theme.set_color("font_unselected_color", "TabContainer", TEXT_DIM)
	theme.set_color("font_hovered_color", "TabContainer", TEXT)

	theme.set_constant("separation", "HSeparator", 12)


## Fonte em negrito para títulos.
static func bold_font() -> Font:
	return _with_fallback(FONT_BOLD)


## Fonte com reserva: símbolos que a Rajdhani não tem (ex.: ∞) usam a do sistema.
static func _with_fallback(font: FontFile) -> FontFile:
	if font.fallbacks.is_empty():
		var system := SystemFont.new()
		system.font_names = PackedStringArray(["Segoe UI", "Arial", "sans-serif"])
		font.fallbacks = [system]
	return font


static func _box(color: Color, border_bottom: int = 0, border_color: Color = Color.TRANSPARENT, radius: int = 2, margin: int = 8) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(radius)
	box.content_margin_left = margin + 6
	box.content_margin_right = margin + 6
	box.content_margin_top = margin * 0.6
	box.content_margin_bottom = margin * 0.6
	box.border_width_bottom = border_bottom
	box.border_color = border_color
	return box
