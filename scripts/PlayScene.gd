extends Control
## PlayScene: redesigned with customer window (top) and work area (bottom).
## Top: customer arrives, shows order. Bottom: player works on orders.
## Better visual separation and windowed feel.

var shift: ShiftManager
var _active_order: Order = null

# UI node references (created in _ready).
var _time_label: Label
var _score_label: Label
var _coins_label: Label
var _customer_window: PanelContainer
var _customer_name: Label
var _customer_visual: PlaceholderArt
var _customer_order_display: Label
var _accept_button: Button
var _waiting_queue_label: Label
var _ticket_rail: HBoxContainer
var _station_label: Label
var _assembly_box: VBoxContainer
var _shelf: GridContainer
var _action_bar: HBoxContainer
var _meter: ProcessMeter
var _feedback: Label

# Per-order interaction state.
var _stage: String = "idle"   # idle -> build -> process -> finish -> ready
var _ticket_buttons: Dictionary = {}   # Order -> Button

const BG := Color(0.062745, 0.054902, 0.145098)
const PANEL := Color(0.11, 0.10, 0.20)
const PANEL_LIGHT := Color(0.15, 0.14, 0.24)
const ACCENT := Color(0.65, 0.45, 0.95)
const ACCENT_BRIGHT := Color(0.85, 0.65, 1.0)

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

# --------------------------------------------------------------------------
# UI CONSTRUCTION  (all code, no scene file needed)
# --------------------------------------------------------------------------
func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Main split: top (customer window) + bottom (work area)
	var main_split := VSplitContainer.new()
	main_split.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_split.split_offset = 300
	main_split.add_theme_constant_override("separation", 16)
	main_split.offset_left = 16
	main_split.offset_top = 16
	main_split.offset_right = -16
	main_split.offset_bottom = -16
	add_child(main_split)

	# --- TOP SECTION: Customer Window ---
	var customer_panel := _make_panel_with_bg(PANEL_LIGHT)
	customer_panel.custom_minimum_size = Vector2(0, 280)
	main_split.add_child(customer_panel)

	_customer_window = customer_panel
	var customer_container := HBoxContainer.new()
	customer_container.add_theme_constant_override("separation", 20)
	customer_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	customer_container.offset_left = 16
	customer_container.offset_top = 16
	customer_container.offset_right = -16
	customer_container.offset_bottom = -16
	customer_panel.add_child(customer_container)

	# Customer visual (left side)
	_customer_visual = PlaceholderArt.new()
	_customer_visual.custom_minimum_size = Vector2(120, 120)
	_customer_visual.setup(Color(0.5, 0.6, 0.9), PlaceholderArt.Shape.ROUNDED_RECT, "")
	customer_container.add_child(_customer_visual)

	# Customer info (middle/right)
	var info_box := VBoxContainer.new()
	info_box.add_theme_constant_override("separation", 8)
	info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	customer_container.add_child(info_box)

	_customer_name = _make_label("Welcome, friend!", 24, Color(0.9, 0.85, 1.0))
	info_box.add_child(_customer_name)

	_customer_order_display = _make_label("Waiting for order...", 18, Color(1, 1, 1, 0.8))
	_customer_order_display.custom_minimum_size = Vector2(0, 60)
	_customer_order_display.autowrap_mode = TextServer.AUTOWRAP_WORD
	info_box.add_child(_customer_order_display)

	_accept_button = _make_button("ACCEPT ORDER", ACCENT_BRIGHT)
	_accept_button.custom_minimum_size = Vector2(200, 54)
	_accept_button.pressed.connect(_accept_current_order)
	_accept_button.disabled = true
	info_box.add_child(_accept_button)

	# --- BOTTOM SECTION: Work Area ---
	var work_area := VBoxContainer.new()
	work_area.add_theme_constant_override("separation", 8)
	main_split.add_child(work_area)

	# Top bar: time / score / coins + queue count
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	_time_label = _make_label("⏱ 90", 20)
	_score_label = _make_label("⭐ 0", 20)
	_coins_label = _make_label("🪙 0", 20)
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_score_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_waiting_queue_label = _make_label("Queue: 0", 18)
	header.add_child(_time_label)
	header.add_child(_score_label)
	header.add_child(_coins_label)
	header.add_child(VSeparator.new())
	header.add_child(_waiting_queue_label)
	work_area.add_child(header)

	# Ticket rail: compact queue display
	var rail_panel := _make_panel()
	rail_panel.custom_minimum_size = Vector2(0, 100)
	work_area.add_child(rail_panel)
	_ticket_rail = HBoxContainer.new()
	_ticket_rail.add_theme_constant_override("separation", 6)
	_ticket_rail.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ticket_rail.offset_left = 8
	_ticket_rail.offset_top = 8
	_ticket_rail.offset_right = -8
	_ticket_rail.offset_bottom = -8
	rail_panel.add_child(_ticket_rail)

	# Station area (label + assembly preview + minigame)
	_station_label = _make_label("Select a ticket to start working", 16, Color(1, 1, 1, 0.7))
	_station_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	work_area.add_child(_station_label)

	var station_panel := _make_panel()
	station_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	work_area.add_child(station_panel)
	_assembly_box = VBoxContainer.new()
	_assembly_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	_assembly_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_assembly_box.offset_left = 8
	_assembly_box.offset_top = 8
	_assembly_box.offset_right = -8
	_assembly_box.offset_bottom = -8
	station_panel.add_child(_assembly_box)

	# Process minigame meter (hidden until process stage).
	_meter = ProcessMeter.new()
	_meter.custom_minimum_size = Vector2(0, 48)
	_meter.visible = false
	_meter.finished.connect(_on_process_finished)
	work_area.add_child(_meter)

	# Ingredient shelf
	_shelf = GridContainer.new()
	_shelf.columns = 5
	_shelf.add_theme_constant_override("h_separation", 6)
	_shelf.add_theme_constant_override("v_separation", 6)
	work_area.add_child(_shelf)

	# Action bar (serve / trash)
	_action_bar = HBoxContainer.new()
	_action_bar.add_theme_constant_override("separation", 12)
	work_area.add_child(_action_bar)

	# Feedback toast
	_feedback = _make_label("", 16)
	_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback.modulate = Color(1, 1, 1, 0)
	work_area.add_child(_feedback)

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
	b.custom_minimum_size = Vector2(0, 50)
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(12)
	b.add_theme_stylebox_override("normal", sb)
	var sbh := sb.duplicate()
	sbh.bg_color = col.lightened(0.1)
	b.add_theme_stylebox_override("hover", sbh)
	return b

func _make_panel() -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = PANEL
	sb.set_corner_radius_all(14)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	p.add_theme_stylebox_override("panel", sb)
	return p

func _make_panel_with_bg(bg_col: Color) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.set_corner_radius_all(14)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	p.add_theme_stylebox_override("panel", sb)
	return p

func _make_action_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 16)
	b.custom_minimum_size = Vector2(0, 46)
	return b

# --------------------------------------------------------------------------
# SHIFT / CUSTOMER ARRIVAL / TICKET EVENTS
# --------------------------------------------------------------------------
func _on_order_spawned(order: Order) -> void:
	# Update customer window with first unaccepted order
	if _active_order == null:
		_show_customer_order(order)
	
	# Add to ticket rail
	var btn := _make_ticket_button(order)
	_ticket_rail.add_child(btn)
	_ticket_buttons[order] = btn
	_update_queue_display()

func _show_customer_order(order: Order) -> void:
	var cust := GameData.get_customer(order.customer_id)
	var recipe := order.recipe()
	var cust_color: Color = cust.get("color", Color(0.5, 0.6, 0.9))
	
	_customer_visual.setup(cust_color, PlaceholderArt.Shape.ROUNDED_RECT, cust.get("name", "?")[0])
	_customer_name.text = cust.get("name", "Mystery Guest")
	_customer_order_display.text = 'Order:\n"%s"' % recipe.get("name", "Unknown Drink")
	_accept_button.disabled = false

func _accept_current_order() -> void:
	# Find the next unaccepted order (peek at queue)
	if shift.queue.size() == 0:
		return
	var order: Order = shift.queue[0]
	_active_order = order
	_stage = "build"
	_accept_button.disabled = true
	_refresh_station()
	_show_next_customer_in_queue()

func _show_next_customer_in_queue() -> void:
	# If there's another customer waiting, show them
	if shift.queue.size() > 1:
		_show_customer_order(shift.queue[1])
	else:
		_customer_order_display.text = "Waiting for next customer..."
		_accept_button.disabled = true

func _make_ticket_button(order: Order) -> Button:
	var btn := _make_action_button("")
	btn.custom_minimum_size = Vector2(100, 0)
	btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var cust := GameData.get_customer(order.customer_id)
	var recipe := order.recipe()
	btn.text = "%s\n%s" % [cust.get("name", "?"), recipe.get("name", "?")]
	btn.pressed.connect(func(): _select_order(order))
	return btn

func _on_order_removed(order: Order, reason: String) -> void:
	if _ticket_buttons.has(order):
		_ticket_buttons[order].queue_free()
		_ticket_buttons.erase(order)
	if order == _active_order and reason == "expired":
		_show_feedback("Customer left! 😢", Color(1, 0.5, 0.5))
		_clear_active()
	_update_queue_display()
	_show_next_customer_in_queue()

func _process(_delta: float) -> void:
	# Update ticket patience bars (color shifts toward red as time runs out).
	for key in _ticket_buttons.keys():
		var order: Order = key
		var btn: Button = _ticket_buttons[order]
		var r: float = order.patience_ratio()
		btn.modulate = Color(1.0, 0.4 + 0.6 * r, 0.4 + 0.6 * r)

func _on_time_changed(seconds_left: float) -> void:
	_time_label.text = "⏱ %d" % int(ceil(seconds_left))

func _on_score_changed(new_score: int) -> void:
	_score_label.text = "⭐ %d" % new_score

func _update_queue_display() -> void:
	_waiting_queue_label.text = "Queue: %d" % shift.queue.size()

# --------------------------------------------------------------------------
# ORDER INTERACTION
# --------------------------------------------------------------------------
func _select_order(order: Order) -> void:
	if _active_order != null and _active_order != order:
		_show_feedback("Finish the current drink first!", Color(1, 0.8, 0.4))
		return
	_active_order = order
	_stage = "build"
	_refresh_station()

func _refresh_station() -> void:
	# Clear dynamic containers.
	for c in _assembly_box.get_children():
		c.queue_free()
	for c in _shelf.get_children():
		c.queue_free()
	for c in _action_bar.get_children():
		c.queue_free()
	_meter.visible = false

	if _active_order == null:
		_station_label.text = "Select a ticket to start working"
		return

	var recipe := _active_order.recipe()
	match _stage:
		"build":
			_station_label.text = "▼ BUILD: Add ingredients in order"
			_show_recipe_target(recipe, "build")
			_populate_shelf(recipe.get("build", []), _tap_build_ingredient)
			var to_process := _make_action_button("▶ Process (%s)" % GameData.get_process(recipe.get("process","")).get("name",""))
			to_process.pressed.connect(_begin_process)
			_action_bar.add_child(to_process)
			_add_trash_button()
		"process":
			_station_label.text = "● PROCESS: Tap to stop in the green zone!"
			_meter.visible = true
			_meter.start(recipe.get("process",""))
		"finish":
			_station_label.text = "▲ FINISH: Add toppings on top"
			_show_recipe_target(recipe, "finish")
			_populate_shelf(recipe.get("finish", []), _tap_finish_ingredient)
			var serve := _make_action_button("✅ SERVE")
			serve.pressed.connect(_serve_active)
			_action_bar.add_child(serve)
			_add_trash_button()

func _show_recipe_target(recipe: Dictionary, which: String) -> void:
	# A row showing what the customer ordered + what the player has added.
	var target: Array = recipe.get(which, [])
	var added: Array = _active_order.added_build if which == "build" else _active_order.added_finish

	var wrap := HBoxContainer.new()
	wrap.alignment = BoxContainer.ALIGNMENT_CENTER
	wrap.add_theme_constant_override("separation", 10)
	for i in range(target.size()):
		var ing := GameData.get_ingredient(target[i])
		var chip := PlaceholderArt.new()
		chip.custom_minimum_size = Vector2(50, 50)
		var done: bool = i < added.size() and added[i] == target[i]
		var col: Color = ing.get("color", Color.GRAY)
		chip.setup(col if done else col.darkened(0.6), PlaceholderArt.Shape.CIRCLE, "")
		wrap.add_child(chip)
	_assembly_box.add_child(wrap)

	# Cup/treat silhouette preview.
	var preview := PlaceholderArt.new()
	preview.custom_minimum_size = Vector2(110, 130)
	var shape := PlaceholderArt.Shape.CUP if recipe.get("type","drink") == "drink" else PlaceholderArt.Shape.CUPCAKE
	preview.setup(ACCENT_BRIGHT, shape, recipe.get("name",""))
	_assembly_box.add_child(preview)

func _populate_shelf(ids: Array, tap_cb: Callable) -> void:
	# Show the needed ingredients PLUS a couple of distractors so it isn't trivial.
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
		b.custom_minimum_size = Vector2(0, 68)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.text = ing.get("name","?")
		b.add_theme_font_size_override("font_size", 11)
		var sb := StyleBoxFlat.new()
		sb.bg_color = ing.get("color", Color.GRAY).darkened(0.2)
		sb.set_corner_radius_all(10)
		b.add_theme_stylebox_override("normal", sb)
		var sbh := sb.duplicate()
		sbh.bg_color = ing.get("color", Color.GRAY)
		b.add_theme_stylebox_override("hover", sbh)
		b.pressed.connect(func(): tap_cb.call(id))
		_shelf.add_child(b)

func _tap_build_ingredient(id: String) -> void:
	_active_order.add_build_ingredient(id)
	_refresh_station()

func _tap_finish_ingredient(id: String) -> void:
	_active_order.add_finish_ingredient(id)
	_refresh_station()

func _begin_process() -> void:
	_stage = "process"
	_refresh_station()

func _on_process_finished(quality: float) -> void:
	if _active_order == null:
		return
	_active_order.set_process_quality(quality)
	var word := "Perfect!" if quality >= 0.95 else ("Good" if quality >= 0.6 else "Overcooked")
	var fb_color := Color(0.5, 1, 0.6) if quality >= 0.6 else Color(1, 0.6, 0.4)
	_show_feedback("%s (%d%%)" % [word, int(quality * 100)], fb_color)
	_stage = "finish"
	_refresh_station()

func _serve_active() -> void:
	if _active_order == null:
		return
	var reward := shift.serve_order(_active_order)
	var stars := "⭐".repeat(int(reward["stars"]))
	_show_feedback("%s  +%d 🪙" % [stars, int(reward["total"])], Color(0.6, 1, 0.7))
	_clear_active()

func _add_trash_button() -> void:
	var trash := _make_action_button("🗑 Discard")
	trash.pressed.connect(func():
		_show_feedback("Order discarded", Color(1, 0.7, 0.5))
		_clear_active())
	_action_bar.add_child(trash)

func _clear_active() -> void:
	_active_order = null
	_stage = "idle"
	_refresh_station()
	_show_next_customer_in_queue()
	_update_queue_display()

# --------------------------------------------------------------------------
# FEEDBACK + SHIFT END
# --------------------------------------------------------------------------
func _show_feedback(text: String, color: Color) -> void:
	_feedback.text = text
	_feedback.modulate = color
	var tw := create_tween()
	tw.tween_property(_feedback, "modulate:a", 1.0, 0.1)
	tw.tween_interval(1.2)
	tw.tween_property(_feedback, "modulate:a", 0.0, 0.4)

func _on_shift_ended(summary: Dictionary) -> void:
	# Stash summary on the SceneTree BEFORE changing scene so the results
	# screen can read it in its _ready().
	get_tree().set_meta("last_summary", summary)
	get_tree().change_scene_to_file("res://scenes/ShiftResults.tscn")
