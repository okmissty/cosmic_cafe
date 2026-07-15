extends Control
class_name PlaceholderArt
## Draws a simple colored shape as stand-in art so the whole game is playable
## with NO image files. When you add real sprites to assets/sprites/, swap
## these nodes for TextureRects — the layout stays the same.
##
## Usage: add as a child, set `fill`, `shape`, and optional `label`.

enum Shape { CIRCLE, ROUNDED_RECT, CUP, CUPCAKE }

@export var fill: Color = Color(0.6, 0.6, 0.9)
@export var outline: Color = Color(1, 1, 1, 0.25)
@export var shape: Shape = Shape.ROUNDED_RECT
@export var label: String = ""

func setup(p_fill: Color, p_shape: Shape, p_label: String = "") -> void:
	fill = p_fill
	shape = p_shape
	label = p_label
	queue_redraw()

func _draw() -> void:
	var s := size
	match shape:
		Shape.CIRCLE:
			var r: float = min(s.x, s.y) * 0.5
			draw_circle(s * 0.5, r, fill)
			draw_arc(s * 0.5, r, 0, TAU, 32, outline, 2.0)
		Shape.ROUNDED_RECT:
			_rounded(Rect2(Vector2.ZERO, s), 10.0, fill)
		Shape.CUP:
			# Simple tapered cup silhouette.
			var top_w: float = s.x * 0.8
			var bot_w: float = s.x * 0.55
			var pts := PackedVector2Array([
				Vector2((s.x - top_w) * 0.5, s.y * 0.12),
				Vector2((s.x + top_w) * 0.5, s.y * 0.12),
				Vector2((s.x + bot_w) * 0.5, s.y * 0.95),
				Vector2((s.x - bot_w) * 0.5, s.y * 0.95),
			])
			draw_colored_polygon(pts, fill)
			# liquid line
			draw_line(Vector2((s.x - top_w) * 0.5, s.y * 0.12),
					  Vector2((s.x + top_w) * 0.5, s.y * 0.12), outline, 2.0)
		Shape.CUPCAKE:
			var base := Rect2(s.x * 0.2, s.y * 0.5, s.x * 0.6, s.y * 0.45)
			_rounded(base, 6.0, fill.darkened(0.25))
			draw_circle(Vector2(s.x * 0.5, s.y * 0.45), s.x * 0.3, fill)

	if label != "":
		var f := ThemeDB.fallback_font
		var fs := 14
		var text_size := f.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
		draw_string(f, Vector2((s.x - text_size.x) * 0.5, s.y + 14),
					label, HORIZONTAL_ALIGNMENT_CENTER, -1, fs, Color(1, 1, 1, 0.85))

func _rounded(rect: Rect2, radius: float, col: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_left = radius
	sb.corner_radius_bottom_right = radius
	draw_style_box(sb, rect)
