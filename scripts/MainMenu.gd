extends Control
## MainMenu: title screen. Shows level/coins, a Play button, and hooks where
## the shop / remove-ads IAP button will live. Built in code so no scene wiring
## is required beyond attaching this script to Main.tscn's root Control.

const BG := Color(0.062745, 0.054902, 0.145098)
const ACCENT := Color(0.65, 0.45, 0.95)

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Simple starfield backdrop.
	var stars := _make_stars()
	add_child(stars)

	# CenterContainer centers its child based on the child's actual size —
	# unlike PRESET_CENTER (which anchors a single point and then grows the
	# content to one side), this keeps everything visually centered.
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 18)
	v.custom_minimum_size = Vector2(400, 0)
	center.add_child(v)

	var title := Label.new()
	title.text = "✦ COSMIC CAFÉ ✦"
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", Color(0.9, 0.8, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)

	var sub := Label.new()
	sub.text = "Serve galactic drinks & sweet treats"
	sub.add_theme_font_size_override("font_size", 16)
	sub.modulate = Color(1, 1, 1, 0.7)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)

	var stats := Label.new()
	stats.text = "Level %d   🪙 %d   Gems %d" % [GameState.level, GameState.coins, GameState.gems]
	stats.add_theme_font_size_override("font_size", 18)
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(stats)

	var play := _big_button("▶  START SHIFT", ACCENT)
	play.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Play.tscn"))
	v.add_child(play)

	var shop := _big_button("🛒  Shop (coming soon)", Color(0.25, 0.30, 0.45))
	shop.pressed.connect(func(): print("Shop pressed — hook IAP / cosmetics here"))
	v.add_child(shop)

	if not GameState.ads_removed:
		var noads := _big_button("✨ Remove Ads (IAP)", Color(0.30, 0.45, 0.35))
		noads.pressed.connect(func(): print("Trigger remove-ads IAP purchase flow here"))
		v.add_child(noads)

func _big_button(text: String, col: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 22)
	b.custom_minimum_size = Vector2(340, 60)
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(16)
	b.add_theme_stylebox_override("normal", sb)
	var sbh := sb.duplicate()
	sbh.bg_color = col.lightened(0.15)
	b.add_theme_stylebox_override("hover", sbh)
	return b

func _make_stars() -> Node2D:
	var n := Node2D.new()
	# Scatter simple star dots as ColorRect children (no custom drawing needed).
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in range(60):
		var dot := ColorRect.new()
		var s := rng.randf_range(1.0, 3.0)
		dot.size = Vector2(s, s)
		dot.position = Vector2(rng.randf_range(0, 720), rng.randf_range(0, 1280))
		dot.color = Color(1, 1, 1, rng.randf_range(0.2, 0.8))
		n.add_child(dot)
	return n
