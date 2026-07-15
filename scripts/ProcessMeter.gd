extends Control
class_name ProcessMeter
## The "process" timing minigame (brew / freeze / bake / blend).
## A marker sweeps across the bar; a highlighted sweet-spot band gives the
## best result. Player taps STOP. Emits `finished(quality)` where quality is
## 0..1 (1.0 = perfectly inside the sweet spot).

signal finished(quality: float)

var _process_id: String = ""
var _duration: float = 3.0
var _sweet_start: float = 0.6
var _sweet_end: float = 0.85
var _accent: Color = Color(0.8, 0.5, 0.2)

var _t: float = 0.0
var _running: bool = false

func start(process_id: String) -> void:
	_process_id = process_id
	var p := GameData.get_process(process_id)
	_duration = float(p.get("duration", 3.0))
	_sweet_start = float(p.get("sweet_start", 0.6))
	_sweet_end = float(p.get("sweet_end", 0.85))
	_accent = p.get("color", _accent)
	_t = 0.0
	_running = true
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	if not _running:
		return
	_t += delta / _duration
	if _t >= 1.0:
		# Ran off the end without tapping -> overcooked, poor quality.
		_t = 1.0
		_stop()
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if not _running:
		return
	if (event is InputEventScreenTouch and event.pressed) or \
	   (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		_stop()

func _stop() -> void:
	_running = false
	set_process(false)
	var q := _quality_at(_t)
	finished.emit(q)

## Quality curve: 1.0 inside the sweet band, falling off linearly outside it.
func _quality_at(pos: float) -> float:
	if pos >= _sweet_start and pos <= _sweet_end:
		return 1.0
	if pos < _sweet_start:
		var d := _sweet_start - pos
		return clampf(1.0 - d / _sweet_start, 0.0, 1.0)
	else:
		var span := 1.0 - _sweet_end
		if span <= 0.0:
			return 0.5
		var d2 := pos - _sweet_end
		return clampf(1.0 - d2 / span, 0.0, 1.0)

func _draw() -> void:
	var s := size
	# Track background with shadow
	var shadow_box := StyleBoxFlat.new()
	shadow_box.bg_color = Color(0, 0, 0, 0.4)
	shadow_box.set_corner_radius_all(8)
	draw_style_box(shadow_box, Rect2(Vector2(0, 2), s))
	
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.12, 0.10, 0.20)
	track.set_corner_radius_all(8)
	draw_style_box(track, Rect2(Vector2.ZERO, s))

	# Sweet-spot band with gradient effect
	var band_start := s.x * _sweet_start
	var band_width := s.x * (_sweet_end - _sweet_start)
	
	# Band shadow
	var band_shadow := StyleBoxFlat.new()
	band_shadow.bg_color = Color(0.35, 0.90, 0.55, 0.2)
	band_shadow.set_corner_radius_all(4)
	draw_style_box(band_shadow, Rect2(band_start, 2, band_width, s.y))
	
	# Main band
	var band_box := StyleBoxFlat.new()
	band_box.bg_color = Color(0.35, 0.90, 0.55, 0.6)
	band_box.set_corner_radius_all(4)
	draw_style_box(band_box, Rect2(band_start, 0, band_width, s.y))
	
	# Highlight on band
	draw_rect(Rect2(band_start, 0, band_width * 0.3, s.y * 0.4), Color(1, 1, 1, 0.2))

	# Moving marker with glow effect
	var mx := s.x * _t
	# Glow
	draw_rect(Rect2(mx - 8, 0, 16, s.y), Color(_accent.r, _accent.g, _accent.b, 0.2))
	# Main marker
	draw_rect(Rect2(mx - 3, 0, 6, s.y), _accent)
	draw_line(Vector2(mx, 0), Vector2(mx, s.y), Color(1, 1, 1, 0.8), 1.5)
	
	# Center text for clarity
	var f := ThemeDB.fallback_font
	var text := "TAP TO STOP"
	var text_size := f.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, 12)
	draw_string(f, Vector2((s.x - text_size.x) * 0.5, s.y * 0.5 - 6),
				text, HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color(1, 1, 1, 0.6))
