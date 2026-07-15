extends RefCounted
class_name Order
## Represents a single customer order moving through the stations.
## The Order stores the target recipe plus what the player has actually done,
## then scores accuracy on serve. Pure data + logic (no nodes), so it's easy
## to unit-test and reuse.

var recipe_id: String
var customer_id: String
var patience: float          # seconds remaining before the customer leaves
var max_patience: float

# --- Player progress on this order ---
var added_build: Array = []      # ingredient ids the player added, in order
var added_finish: Array = []     # topping ids the player added, in order
var process_quality: float = 0.0 # 0..1 result of the timing minigame
var current_stage: String = "order"  # order -> build -> process -> finish -> done

func _init(p_recipe_id: String, p_customer_id: String) -> void:
	recipe_id = p_recipe_id
	customer_id = p_customer_id
	var cust := GameData.get_customer(customer_id)
	max_patience = float(cust.get("patience", 25.0))
	patience = max_patience

func recipe() -> Dictionary:
	return GameData.get_recipe(recipe_id)

func tick_patience(delta: float) -> void:
	patience = max(0.0, patience - delta)

func patience_ratio() -> float:
	if max_patience <= 0.0:
		return 0.0
	return patience / max_patience

func is_expired() -> bool:
	return patience <= 0.0

# --- Player actions -------------------------------------------------------
func add_build_ingredient(id: String) -> void:
	added_build.append(id)

func add_finish_ingredient(id: String) -> void:
	added_finish.append(id)

func set_process_quality(q: float) -> void:
	process_quality = clampf(q, 0.0, 1.0)

# --- Scoring --------------------------------------------------------------
## Compares an added list to the target list, order-sensitive.
## Returns 0..1 fraction of correct positions.
func _sequence_accuracy(added: Array, target: Array) -> float:
	if target.is_empty():
		return 1.0
	var correct := 0
	for i in range(target.size()):
		if i < added.size() and added[i] == target[i]:
			correct += 1
	# Penalize extra wrong additions slightly.
	var extras := max(0, added.size() - target.size())
	var raw := float(correct) / float(target.size())
	return clampf(raw - 0.15 * extras, 0.0, 1.0)

## Overall accuracy 0..1 combining build order, toppings, and process timing.
func accuracy() -> float:
	var r := recipe()
	var build_acc := _sequence_accuracy(added_build, r.get("build", []))
	var finish_acc := _sequence_accuracy(added_finish, r.get("finish", []))
	# Weighting: build 45%, finish 25%, process 30%.
	return build_acc * 0.45 + finish_acc * 0.25 + process_quality * 0.30

## Coins + tip earned for this order given final accuracy and patience left.
## Returns a dict: { "base": int, "tip": int, "total": int, "stars": int }
func compute_reward() -> Dictionary:
	var r := recipe()
	var acc := accuracy()
	var base_price := int(r.get("base_price", 10))
	var base := int(round(base_price * acc))

	# Tip scales with accuracy AND with how much patience was left (speed).
	var cust := GameData.get_customer(customer_id)
	var tip_mult := float(cust.get("tip_mult", 1.0))
	var speed_bonus := patience_ratio()  # 0..1
	var tip := int(round(base_price * 0.5 * acc * speed_bonus * tip_mult))

	var total := base + tip
	# Star rating for feedback (1-3).
	var stars := 1
	if acc >= 0.9:
		stars = 3
	elif acc >= 0.65:
		stars = 2

	return {"base": base, "tip": tip, "total": total, "stars": stars, "accuracy": acc}
