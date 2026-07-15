extends Control
## PlayScene v3: one customer at a time, easier early levels, clear build feedback,
## and drag-to-decorate toppings.

var shift: ShiftManager
var _active_order: Order = null
var _current_build: Array = []
var _current_toppings: Array = []
var _dragging_topping: String = ""
var _dragging_visual: Control = null

# UI node references
var _time_label: Label
var _score_label: Label
var _coins_label: Label
var _customer_visual: PlaceholderArt
var _customer_name: Label
var _customer_order_display: Label
var _station_label: Label
var _build_box: VBoxContainer
var _shelf: GridContainer
var _process_button: Button
var _meter: ProcessMeter
var _cup_preview: Control
var _topping_preview_area: Control
var _feedback: Label

const BG := Color(0.062745, 0.054902, 0.145098)
const PANEL := Color(0.11, 0.10, 0.20)
const PANEL_LIGHT := Color(0.15, 0.14, 0.24)
const ACCENT := Color(0.65, 0.45, 0.95)
const ACCENT_BRIGHT := Color(0.85, 0.65, 1.0)
const SUCCESS := Color(0.4, 0.9, 0.5)
const FAIL := Color(1.0, 0.35, 0.35)

func _ready() -> void:
	_build_ui()
	shift = ShiftManager.new()
	add_child(shift)
	shift.order_spawned.connect(_on_order_spawned)
	shift.order_removed.connect(_on_order_removed)
	shift.shift_time_changed.connect(_on_time_changed)
	shift.score_changed.connect(_on_score_changed)
	shift.shift_ended.connect(_on_shift_ended)
	GameState.coins_changed.connect(func(c): _coins_label.text = "🪙 %d" % c)
	_coins_label.text = "🪙 %d" % GameState.coins
	shift.start_shift()

func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 14)
	root.offset_left = 16
	root.offset_top = 16
	root.offset_right = -16
	root.offset_bottom = -16
	add_child(root)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	_time_label = _make_label("⏱ 90", 20)
	_score_label = _make_label("⭐ 0", 20)
	_coins_label = _make_label("🪙 0", 20)
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_score_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_time_label)
	header.add_child(_score_label)
	header.add_child(_coins_label)
	root.add_child(header)

	var customer_panel := _make_panel_with_bg(PANEL_LIGHT)
	customer_panel.custom_minimum_size = Vector2(0, 220)
	root.add_child(customer_panel)

	var customer_hbox := HBoxContainer.new()
	customer_hbox.add_theme_constant_override("separation", 18)
	customer_hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	customer_hbox.offset_left = 16
	customer_hbox.offset_top = 16
	customer_hbox.offset_right = -16
	customer_hbox.offset_bottom = -16
	customer_panel.add_child(customer_hbox)

	_customer_visual = PlaceholderArt.new()
	_customer_visual.custom_minimum_size = Vector2(120, 120)
	_customer_visual.setup(Color(0.6, 0.7, 1.0), PlaceholderArt.Shape.CIRCLE, "")
	customer_hbox.add_child(_customer_visual)

	var customer_info := VBoxContainer.new()
	customer_info.add_theme_constant_override("separation", 8)
	customer_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	customer_hbox.add_child(customer_info)

	_customer_name = _make_label("Waiting for customer...", 26, Color(0.95, 0.85, 1.0))
	customer_info.add_child(_customer_name)

	_customer_order_display = _make_label("No active order yet.", 16, Color(1, 1, 1, 0.8))
	_customer_order_display.autowrap_mode = TextServer.AUTOWRAP_WORD
	_customer_order_display.custom_minimum_size = Vector2(0, 80)
	customer_info.add_child(_customer_order_display)

	var work_panel := _make_panel()
	work_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(work_panel)

	var work_vbox := VBoxContainer.new()
	work_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	work_vbox.offset_left = 14
	work_vbox.offset_top = 14
	work_vbox.offset_right = -14
	work_vbox.offset_bottom = -14
	work_vbox.add_theme_constant_override("separation", 12)
	work_panel.add_child(work_vbox)

	_station_label = _make_label("Build the drink by selecting ingredients in the right order.", 18, Color(1, 1, 1, 0.9))
	_station_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	work_vbox.add_child(_station_label)

	_build_box = VBoxContainer.new()
	_build_box.add_theme_constant_override("separation", 10)
	work_vbox.add_child(_build_box)

	_shelf = GridContainer.new()
	_shelf.columns = 4
	_shelf.add_theme_constant_override("h_separation", 8)
	_shelf.add_theme_constant_override("v_separation", 8)
	work_vbox.add_child(_shelf)

	_process_button = _make_action_button("▶ Process")
	_process_button.pressed.connect(_begin_process)
	_process_button.visible = false
	_process_button.disabled = true
	work_vbox.add_child(_process_button)

	_meter = ProcessMeter.new()
	_meter.custom_minimum_size = Vector2(0, 52)
	_meter.visible = false
	_meter.finished.connect(_on_process_finished)
	work_vbox.add_child(_meter)

	var finish_panel := HBoxContainer.new()
	finish_panel.add_theme_constant_override("separation", 14)
	finish_panel.custom_minimum_size = Vector2(0, 220)
	work_vbox.add_child(finish_panel)

	_cup_preview = _make_cup_preview()
	finish_panel.add_child(_cup_preview)

	_topping_preview_area = Control.new()
	_topping_preview_area.custom_minimum_size = Vector2(0, 220)
	_topping_preview_area.add_theme_stylebox_override("panel", _make_finish_stylebox())
	finish_panel.add_child(_topping_preview_area)

	_feedback = _make_label("", 16)
	_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback.modulate = Color(1, 1, 1, 0)
	work_vbox.add_child(_feedback)

func _make_label(text: String, fs: int, col: Color = Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", col)
	return l

func _make_button(text: String, col: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 18)
	b.custom_minimum_size = Vector2(0, 52)
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(12)
	b.add_theme_stylebox_override("normal", sb)
	var sbh := sb.duplicate()
	sbh.bg_color = col.lightened(0.08)
	b.add_theme_stylebox_override("hover", sbh)
	return b

func _make_action_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 16)
	b.custom_minimum_size = Vector2(0, 46)
	return b

func _make_panel() -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = PANEL
	sb.set_corner_radius_all(16)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	p.add_theme_stylebox_override("panel", sb)
	return p

func _make_panel_with_bg(bg_col: Color) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.set_corner_radius_all(16)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	p.add_theme_stylebox_override("panel", sb)
	return p

func _make_cup_preview() -> Control:
	var container := Control.new()
	container.custom_minimum_size = Vector2(180, 220)
	container.add_theme_stylebox_override("panel", _make_finish_stylebox())
	var label := _make_label("Drag toppings here", 14, Color(1, 1, 1, 0.7))
	label.position = Vector2(14, 10)
	container.add_child(label)
	return container

func _make_finish_stylebox() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.10, 0.18)
	sb.set_corner_radius_all(14)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb

func _on_order_spawned(order: Order) -> void:
	if _active_order == null:
		_assign_next_order()

func _assign_next_order() -> void:
	if shift.queue.size() == 0:
		_active_order = null
		_customer_name.text = "Waiting for customer..."
		_customer_order_display.text = "A new customer will arrive soon."
		_refresh_station()
		return
	_active_order = shift.queue[0]
	_current_build.clear()
	_current_toppings.clear()
	_update_customer_window()
	_refresh_station()

func _update_customer_window() -> void:
	if _active_order == null:
		return
	var cust := GameData.get_customer(_active_order.customer_id)
	var recipe := _active_order.recipe()
	_customer_visual.setup(cust.get("color", Color(0.6, 0.7, 1.0)), PlaceholderArt.Shape.CIRCLE, cust.get("name", "?")[0])
	_customer_name.text = cust.get("name", "Customer")
	_customer_order_display.text = "Order: %s\nBuild: %s\nFinish: %s" % [
		recipe.get("name", "Unknown"),
		_join_ingredient_names(recipe.get("build", [])),
		_join_ingredient_names(recipe.get("finish", []))
	]

func _join_ingredient_names(ids: Array) -> String:
	var names := []
	for id in ids:
		names.append(GameData.get_ingredient(id).get("name", "?"))
	return ", ".join(names)

func _on_order_removed(order: Order, reason: String) -> void:
	if order == _active_order:
		_assign_next_order()

func _process(_delta: float) -> void:
	# Keep dragged visual following the mouse
	if _dragging_visual != null and get_viewport().get_mouse_position() != Vector2.ZERO:
		_dragging_visual.global_position = get_viewport().get_mouse_position() - Vector2(16, 16)

func _on_time_changed(seconds_left: float) -> void:
	_time_label.text = "⏱ %d" % int(ceil(seconds_left))

func _on_score_changed(new_score: int) -> void:
	_score_label.text = "⭐ %d" % new_score

func _refresh_station() -> void:
	_build_box.clear()
	_shelf.clear()
	_process_button.visible = false
	_process_button.disabled = true
	_meter.visible = false
	_cup_preview.clear()
	_current_toppings = []

	if _active_order == null:
		_station_label.text = "Waiting for the next customer..."
		return

	var recipe := _active_order.recipe()
	if _stage == "build":
		_station_label.text = "BUILD: select ingredients in order"
		_show_build_status(recipe)
		_populate_build_shelf(recipe.get("build", []))
		if _current_build.size() == recipe.get("build", []).size():
			_process_button.visible = true
			_process_button.disabled = false
			_process_button.text = "▶ Process (%s)" % GameData.get_process(recipe.get("process", "")).get("name", "")
		else:
			_process_button.visible = false
			_process_button.disabled = true
			_process_button.text = "▶ Process"
	elif _stage == "process":
		_station_label.text = "%s — tap to stop in the green zone!" % GameData.get_process(recipe.get("process", "")).get("name", "")
		_meter.visible = true
		_meter.start(recipe.get("process", ""))
	elif _stage == "finish":
		_station_label.text = "FINISH: drag toppings onto the cup"
		_show_build_status(recipe)
		_populate_finish_shelf(recipe.get("finish", []))

func _show_build_status(recipe: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	for id in recipe.get("build", []):
		var ing := GameData.get_ingredient(id)
		var chip := PlaceholderArt.new()
		chip.custom_minimum_size = Vector2(44, 44)
		var selected := _current_build.has(id) and _current_build.size() > recipe.get("build", []).find(id)
		var col := ing.get("color", Color.GRAY)
		chip.setup(selected ? col.lightened(0.15) : col.darkened(0.4), PlaceholderArt.Shape.CIRCLE, "")
		row.add_child(chip)
	_build_box.add_child(row)
	var status := _make_label("%d / %d correct" % [_current_build.size(), recipe.get("build", []).size()], 14, Color(1, 1, 1, 0.7))
	_build_box.add_child(status)

func _populate_build_shelf(ids: Array) -> void:
	var options: Array = ids.duplicate()
	for extra_id in GameData.INGREDIENTS.keys():
		if options.size() >= 5:
			break
		if not options.has(extra_id):
			options.append(extra_id)
	options.shuffle()

	for id in options:
		var ing := GameData.get_ingredient(id)
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 70)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.text = ing.get("name", "?")
		b.add_theme_font_size_override("font_size", 12)
		var sb := StyleBoxFlat.new()
		var selected := _current_build.has(id)
		sb.bg_color = selected ? ing.get("color", Color.GRAY).lightened(0.2) : ing.get("color", Color.GRAY).darkened(0.15)
		sb.set_corner_radius_all(10)
		b.add_theme_stylebox_override("normal", sb)
		var sbh := sb.duplicate()
		sbh.bg_color = selected ? ing.get("color", Color.GRAY).lightened(0.3) : ing.get("color", Color.GRAY).lightened(0.05)
		b.add_theme_stylebox_override("hover", sbh)
		b.pressed.connect(func(): _tap_build_ingredient(id))
		_shelf.add_child(b)

func _populate_finish_shelf(ids: Array) -> void:
	for id in ids:
		var ing := GameData.get_ingredient(id)
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 70)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.text = ing.get("name", "?")
		b.add_theme_font_size_override("font_size", 12)
		var sb := StyleBoxFlat.new()
		sb.bg_color = ing.get("color", Color.GRAY).darkened(0.15)
		sb.set_corner_radius_all(10)
		b.add_theme_stylebox_override("normal", sb)
		var sbh := sb.duplicate()
		sbh.bg_color = ing.get("color", Color.GRAY).lightened(0.05)
		b.add_theme_stylebox_override("hover", sbh)
		b.pressed.connect(func(): _begin_topping_drag(id))
		_shelf.add_child(b)

func _tap_build_ingredient(id: String) -> void:
	if _active_order == null:
		return
	var recipe := _active_order.recipe()
	var target := recipe.get("build", [])
	var next_index := _current_build.size()
	if next_index >= target.size() or id != target[next_index]:
		_reset_build()
		_show_feedback("Wrong ingredient! New glass ready.", FAIL)
		return
	_current_build.append(id)
	_active_order.added_build = _current_build.duplicate()
	_show_feedback("Added %s" % GameData.get_ingredient(id).get("name", ""), SUCCESS)
	_refresh_station()

func _begin_process() -> void:
	_stage = "process"
	_process_button.visible = false
	_refresh_station()

func _on_process_finished(quality: float) -> void:
	if _active_order == null:
		return
	_active_order.set_process_quality(quality)
	var word := "Perfect!" if quality >= 0.95 else ("Good" if quality >= 0.6 else "Overcooked")
	_show_feedback("%s (%d%%)" % [word, int(quality * 100)], quality >= 0.6 ? SUCCESS : FAIL)
	_stage = "finish"
	_refresh_station()

func _begin_topping_drag(id: String) -> void:
	_dragging_topping = id
	if _dragging_visual != null:
		_dragging_visual.queue_free()
	_dragging_visual = Label.new()
	_dragging_visual.text = GameData.get_ingredient(id).get("name", "")
	_dragging_visual.add_theme_font_size_override("font_size", 14)
	_dragging_visual.add_theme_color_override("font_color", Color.WHITE)
	add_child(_dragging_visual)

func _input(event: InputEvent) -> void:
	if _dragging_topping == "":
		return
	if event is InputEventMouseMotion:
		if _dragging_visual != null:
			_dragging_visual.global_position = event.position + Vector2(10, 10)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if _dragging_visual != null:
			var cup_rect := _cup_preview.get_global_rect()
			if cup_rect.has_point(event.position):
				_complete_topping(_dragging_topping)
			else:
				_show_feedback("Drop the topping on the cup.", Color(1, 0.8, 0.4))
			_dragging_visual.queue_free()
			_dragging_visual = null
			_dragging_topping = ""

func _complete_topping(id: String) -> void:
	if _active_order == null:
		return
	_current_toppings.append(id)
	_active_order.added_finish.append(id)
	var ing := GameData.get_ingredient(id)
	var dot := PlaceholderArt.new()
	dot.custom_minimum_size = Vector2(24, 24)
	dot.setup(ing.get("color", Color(1, 1, 1)), PlaceholderArt.Shape.CIRCLE, "")
	dot.position = Vector2(20 + _current_toppings.size() * 28, 130)
	_cup_preview.add_child(dot)
	_show_feedback("Topping added: %s" % ing.get("name", ""), SUCCESS)

func _reset_build() -> void:
	_current_build.clear()
	if _active_order != null:
		_active_order.added_build = []
	_refresh_station()

func _clear_active() -> void:
	_active_order = null
	_stage = "idle"
	_current_build.clear()
	_current_toppings.clear()
	_refresh_station()

func _show_feedback(text: String, color: Color) -> void:
	_feedback.text = text
	_feedback.modulate = color
	var tw := create_tween()
	tw.tween_property(_feedback, "modulate:a", 1.0, 0.1)
	tw.tween_interval(1.2)
	tw.tween_property(_feedback, "modulate:a", 0.0, 0.4)

func _on_shift_ended(summary: Dictionary) -> void:
	get_tree().set_meta("last_summary", summary)
	get_tree().change_scene_to_file("res://scenes/ShiftResults.tscn")
