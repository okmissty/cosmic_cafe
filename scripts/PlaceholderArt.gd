extends Control
class_name PlaceholderArt
## Draws improved placeholder art with shadows and better visual style.
## Serves as stand-in until real sprites are ready.

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
			# Shadow
			draw_circle(s * 0.5 + Vector2(2, 3), r, Color(0, 0, 0, 0.3))
			# Main shape
			draw_circle(s * 0.5, r, fill)
			# Highlight
			draw_circle(s * 0.5 - Vector2(r * 0.3, r * 0.3), r * 0.25, Color(1, 1, 1, 0.35))
			# Outline
			draw_arc(s * 0.5, r, 0, TAU, 32, outline, 2.0)
			
		Shape.ROUNDED_RECT:
			_rounded(Rect2(Vector2.ZERO, s), 10.0, fill)
			# Add subtle gradient effect with lighter top
			var top_rect := Rect2(0, 0, s.x, s.y * 0.3)
			var gradient_box := StyleBoxFlat.new()
			gradient_box.bg_color = Color(1, 1, 1, 0.08)
			gradient_box.corner_radius_top_left = 10
			gradient_box.corner_radius_top_right = 10
			draw_style_box(gradient_box, top_rect)
			
		Shape.CUP:
			# Tapered cup with gradient and shine
			var top_w: float = s.x * 0.8
			var bot_w: float = s.x * 0.55
			var pts := PackedVector2Array([
				Vector2((s.x - top_w) * 0.5, s.y * 0.12),
				Vector2((s.x + top_w) * 0.5, s.y * 0.12),
				Vector2((s.x + bot_w) * 0.5, s.y * 0.95),
				Vector2((s.x - bot_w) * 0.5, s.y * 0.95),
			])
			# Shadow
			var shadow_pts := pts.duplicate()
			for i in range(shadow_pts.size()):
				shadow_pts[i] += Vector2(2, 3)
			draw_colored_polygon(shadow_pts, Color(0, 0, 0, 0.2))
			# Main cup
			draw_colored_polygon(pts, fill)
			# Liquid shine
			var shine_pts := PackedVector2Array([
				Vector2((s.x - top_w) * 0.5 + 4, s.y * 0.12),
				Vector2((s.x - top_w) * 0.5 + 12, s.y * 0.35),
				Vector2((s.x - top_w) * 0.5 + 8, s.y * 0.12),
			])
			draw_colored_polygon(shine_pts, Color(1, 1, 1, 0.25))
			# Rim
			draw_line(Vector2((s.x - top_w) * 0.5, s.y * 0.12),
					  Vector2((s.x + top_w) * 0.5, s.y * 0.12), Color(1, 1, 1, 0.4), 2.5)
			# Base line
			draw_line(Vector2((s.x - bot_w) * 0.5, s.y * 0.95),
					  Vector2((s.x + bot_w) * 0.5, s.y * 0.95), Color(0, 0, 0, 0.2), 1.5)
			
		Shape.CUPCAKE:
			# Cupcake wrapper (bottom) with ridges
			var base := Rect2(s.x * 0.2, s.y * 0.5, s.x * 0.6, s.y * 0.45)
			var wrapper_col := fill.darkened(0.35)
			_rounded(base, 6.0, wrapper_col)
			# Add wrapper texture (vertical lines)
			for i in range(int(base.size.x / 8)):
				var x: float = base.position.x + i * 8.0
				draw_line(Vector2(x, base.position.y), Vector2(x, base.position.y + base.size.y), 
						  Color(0, 0, 0, 0.1), 0.5)
			
			# Frosting (top) - swirled cupcake
			var frosting_col := fill
			draw_circle(Vector2(s.x * 0.5, s.y * 0.45), s.x * 0.3, frosting_col)
			# Frosting highlight
			draw_circle(Vector2(s.x * 0.5 - s.x * 0.08, s.y * 0.35), s.x * 0.12, Color(1, 1, 1, 0.3))
			# Frosting swirl detail
			var swirl_pts := PackedVector2Array([
				Vector2(s.x * 0.5, s.y * 0.2),
				Vector2(s.x * 0.65, s.y * 0.35),
				Vector2(s.x * 0.5, s.y * 0.4),
				Vector2(s.x * 0.35, s.y * 0.35),
			])
			draw_colored_polygon(swirl_pts, frosting_col.lightened(0.15))
			
			# Cherry on top
			var cherry_col := Color(1.0, 0.2, 0.3)
			draw_circle(Vector2(s.x * 0.5, s.y * 0.15), s.x * 0.08, cherry_col)
			draw_circle(Vector2(s.x * 0.5, s.y * 0.12), s.x * 0.08 * 0.5, Color(1, 1, 1, 0.2))

	# Label (centered at bottom)
	if label != "":
		var f := ThemeDB.fallback_font
		var fs := 14
		var text_size := f.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
		draw_string(f, Vector2((s.x - text_size.x) * 0.5, s.y + 14),
					label, HORIZONTAL_ALIGNMENT_CENTER, -1, fs, Color(1, 1, 1, 0.9))

func _rounded(rect: Rect2, radius: float, col: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_left = radius
	sb.corner_radius_bottom_right = radius
	draw_style_box(sb, rect)
