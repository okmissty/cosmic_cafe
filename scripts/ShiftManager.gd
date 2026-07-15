extends Node
class_name ShiftManager
## Drives one "shift" of the cafe: spawns customer orders on a timer,
## tracks the queue, expires impatient customers, totals the score, and
## ends the shift after a set duration. The UI listens to its signals.

signal order_spawned(order: Order)
signal order_removed(order: Order, reason: String)   # reason: "served" | "expired"
signal order_served(order: Order, reward: Dictionary)
signal shift_time_changed(seconds_left: float)
signal score_changed(new_score: int)
signal shift_ended(summary: Dictionary)

@export var shift_duration: float = 90.0    # seconds per shift
@export var max_queue: int = 4              # how many customers wait at once
@export var spawn_interval: float = 6.0     # seconds between spawns

var _time_left: float = 0.0
var _spawn_timer: float = 0.0
var _active := false

var queue: Array[Order] = []
var score: int = 0
var served_count: int = 0
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	set_process(false)

func start_shift() -> void:
	# Difficulty scaling based on player level.
	# Level 1 = baseline, level 3+ = noticeably harder.
	var level_mult: float = 0.9 + (GameState.level - 1) * 0.15
	var adjusted_spawn: float = spawn_interval / level_mult
	var adjusted_queue: int = max_queue + (GameState.level - 1) / 2
	
	_time_left = shift_duration
	_spawn_timer = 1.0        # first customer arrives quickly
	score = 0
	served_count = 0
	queue.clear()
	_active = true
	set_process(true)
	score_changed.emit(score)
	shift_time_changed.emit(_time_left)

func _process(delta: float) -> void:
	if not _active:
		return

	# Shift countdown.
	_time_left -= delta
	shift_time_changed.emit(max(0.0, _time_left))
	if _time_left <= 0.0:
		_end_shift()
		return

	# Customer spawning with level-based difficulty.
	var level_mult: float = 0.9 + (GameState.level - 1) * 0.15
	var adjusted_spawn: float = spawn_interval / level_mult
	var adjusted_queue: int = max_queue + (GameState.level - 1) / 2
	
	_spawn_timer -= delta
	if _spawn_timer <= 0.0 and queue.size() < adjusted_queue:
		_spawn_order()
		# Spawns speed up slightly as the shift progresses (difficulty ramp).
		var progress := 1.0 - (_time_left / shift_duration)
		_spawn_timer = lerpf(adjusted_spawn, adjusted_spawn * 0.5, progress)

	# Tick patience; expire customers who waited too long.
	for order in queue.duplicate():
		order.tick_patience(delta)
		if order.is_expired():
			_remove_order(order, "expired")

func _spawn_order() -> void:
	var available: Array = GameData.recipes_for_level(GameState.level)
	if available.is_empty():
		return
	var recipe_id: String = available[_rng.randi_range(0, available.size() - 1)]
	var cust_ids: Array = GameData.customer_ids()
	var customer_id: String = cust_ids[_rng.randi_range(0, cust_ids.size() - 1)]
	var order := Order.new(recipe_id, customer_id)
	queue.append(order)
	order_spawned.emit(order)

func _remove_order(order: Order, reason: String) -> void:
	var idx := queue.find(order)
	if idx != -1:
		queue.remove_at(idx)
	order_removed.emit(order, reason)

## Called by the play scene when the player finishes and serves an order.
func serve_order(order: Order) -> Dictionary:
	var reward := order.compute_reward()
	score += int(reward["total"])
	served_count += 1
	GameState.add_coins(int(reward["total"]))
	GameState.add_xp(3 + int(reward["stars"]) * 2)  # more xp for better serves
	score_changed.emit(score)
	order_served.emit(order, reward)
	_remove_order(order, "served")
	return reward

func _end_shift() -> void:
	_active = false
	set_process(false)
	var summary := {
		"score": score,
		"served": served_count,
		"is_best": score > GameState.best_shift_score,
	}
	GameState.record_shift(score, served_count)
	shift_ended.emit(summary)

func is_active() -> bool:
	return _active
