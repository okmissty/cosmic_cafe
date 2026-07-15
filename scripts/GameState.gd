extends Node
## GameState (Autoload / Singleton)
## Holds persistent player progression and money. Saves to user:// as JSON.
## Kept separate from GameData (static content) so saves stay small and safe.

signal coins_changed(new_total: int)
signal level_changed(new_level: int)
signal gems_changed(new_total: int)

const SAVE_PATH := "user://cosmic_cafe_save.json"

# --- Persistent fields ----------------------------------------------------
var coins: int = 50          # soft currency, earned by serving
var gems: int = 0            # premium currency (IAP + occasional rewards)
var level: int = 1           # unlocks recipes as it rises
var xp: int = 0              # progress toward next level
var total_served: int = 0    # lifetime stat
var best_shift_score: int = 0
var ads_removed: bool = false          # set true after remove-ads IAP
var owned_cosmetics: Array = []        # cosmetic ids purchased

# XP required to reach the NEXT level (index = current level - 1).
const XP_CURVE := [50, 120, 220, 360, 540, 760, 1040, 1400]

func _ready() -> void:
	load_game()

# --- Currency helpers -----------------------------------------------------
func add_coins(amount: int) -> void:
	coins = max(0, coins + amount)
	coins_changed.emit(coins)
	save_game()

func spend_coins(amount: int) -> bool:
	if coins < amount:
		return false
	coins -= amount
	coins_changed.emit(coins)
	save_game()
	return true

func add_gems(amount: int) -> void:
	gems = max(0, gems + amount)
	gems_changed.emit(gems)
	save_game()

func spend_gems(amount: int) -> bool:
	if gems < amount:
		return false
	gems -= amount
	gems_changed.emit(gems)
	save_game()
	return true

# --- Progression ----------------------------------------------------------
func add_xp(amount: int) -> void:
	xp += amount
	while level - 1 < XP_CURVE.size() and xp >= XP_CURVE[level - 1]:
		xp -= XP_CURVE[level - 1]
		level += 1
		level_changed.emit(level)
	save_game()

func xp_to_next() -> int:
	if level - 1 < XP_CURVE.size():
		return XP_CURVE[level - 1]
	return XP_CURVE[-1]  # cap: keep last requirement for post-curve levels

func record_shift(score: int, served: int) -> void:
	total_served += served
	best_shift_score = max(best_shift_score, score)
	save_game()

func own_cosmetic(id: String) -> void:
	if not owned_cosmetics.has(id):
		owned_cosmetics.append(id)
		save_game()

# --- Save / Load ----------------------------------------------------------
func to_dict() -> Dictionary:
	return {
		"coins": coins,
		"gems": gems,
		"level": level,
		"xp": xp,
		"total_served": total_served,
		"best_shift_score": best_shift_score,
		"ads_removed": ads_removed,
		"owned_cosmetics": owned_cosmetics,
	}

func from_dict(d: Dictionary) -> void:
	coins = int(d.get("coins", coins))
	gems = int(d.get("gems", gems))
	level = int(d.get("level", level))
	xp = int(d.get("xp", xp))
	total_served = int(d.get("total_served", total_served))
	best_shift_score = int(d.get("best_shift_score", best_shift_score))
	ads_removed = bool(d.get("ads_removed", ads_removed))
	owned_cosmetics = d.get("owned_cosmetics", owned_cosmetics)

func save_game() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("Could not open save file for writing.")
		return
	f.store_string(JSON.stringify(to_dict()))
	f.close()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var txt := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(txt)
	if typeof(parsed) == TYPE_DICTIONARY:
		from_dict(parsed)

## Debug helper: wipe the save (call from a dev button if needed).
func reset_save() -> void:
	coins = 50
	gems = 0
	level = 1
	xp = 0
	total_served = 0
	best_shift_score = 0
	ads_removed = false
	owned_cosmetics = []
	save_game()
	coins_changed.emit(coins)
	gems_changed.emit(gems)
	level_changed.emit(level)
