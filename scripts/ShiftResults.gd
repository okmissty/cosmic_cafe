extends Control
## ShiftResults: shown when a shift ends. Displays score/served, a NEW BEST
## flag, and two buttons: continue, and a rewarded-ad "2x coins" button that
## is where your real ad SDK call goes. Built in code.

const BG := Color(0.062745, 0.054902, 0.145098)
const ACCENT := Color(0.65, 0.45, 0.95)

var _summary: Dictionary = {}
var _bonus_claimed := false

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	if get_tree().has_meta("last_summary"):
		_summary = get_tree().get_meta("last_summary")

	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 16)
	v.custom_minimum_size = Vector2(400, 0)
	center.add_child(v)

	var title := _label("SHIFT COMPLETE", 36, Color(0.9, 0.85, 1.0))
	v.add_child(title)

	if _summary.get("is_best", false):
		v.add_child(_label("★ NEW BEST! ★", 24, Color(1.0, 0.85, 0.3)))

	v.add_child(_label("Score: %d" % int(_summary.get("score", 0)), 26, Color.WHITE))
	v.add_child(_label("Customers served: %d" % int(_summary.get("served", 0)), 20, Color(1,1,1,0.85)))
	v.add_child(_label("Level %d   🪙 %d" % [GameState.level, GameState.coins], 20, Color(1,1,1,0.85)))

	# Rewarded-ad button: doubles this shift's coin earnings.
	var earned := int(_summary.get("score", 0))
	var bonus_btn := _button("📺 Watch ad: +%d 🪙 bonus" % earned, Color(0.30, 0.45, 0.35))
	bonus_btn.pressed.connect(func():
		if _bonus_claimed:
			return
		# TODO: call rewarded ad SDK; grant reward in its success callback.
		# Placeholder grants immediately so the flow is testable.
		GameState.add_coins(earned)
		_bonus_claimed = true
		bonus_btn.text = "✅ Bonus claimed!"
		bonus_btn.disabled = true)
	if not GameState.ads_removed:
		v.add_child(bonus_btn)

	var again := _button("▶ Play again", ACCENT)
	again.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Play.tscn"))
	v.add_child(again)

	var menu := _button("🏠 Main menu", Color(0.25, 0.30, 0.45))
	menu.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Main.tscn"))
	v.add_child(menu)

func _label(text: String, fs: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", col)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

func _button(text: String, col: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 20)
	b.custom_minimum_size = Vector2(340, 56)
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(14)
	b.add_theme_stylebox_override("normal", sb)
	return b
