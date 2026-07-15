extends Node
## GameData (Autoload / Singleton)
## Central content database: ingredients, recipes, customers.
## Everything the designer tunes lives here so gameplay code stays generic.
## Add new drinks/treats by adding entries to RECIPES — no code changes needed.

# ---------------------------------------------------------------------------
# INGREDIENTS
# Each ingredient has an id, display name, category, and a color for the
# placeholder art (a colored circle stands in until real sprites are dropped
# into assets/sprites/ingredients/<id>.png).
# ---------------------------------------------------------------------------
const INGREDIENTS := {
	# --- Bases (go in first) ---
	"cold_brew":   {"name": "Cold Brew",       "category": "base",    "color": Color(0.28, 0.18, 0.12)},
	"espresso":    {"name": "Void Espresso",   "category": "base",    "color": Color(0.10, 0.07, 0.05)},
	"slush_ice":   {"name": "Comet Ice",       "category": "base",    "color": Color(0.75, 0.90, 1.00)},
	"cocoa":       {"name": "Cocoa Base",      "category": "base",    "color": Color(0.35, 0.22, 0.16)},
	"lemonade":    {"name": "Star Lemonade",   "category": "base",    "color": Color(0.98, 0.92, 0.45)},

	# --- Syrups / liquids (colorful, on-theme) ---
	"nebula_syrup":  {"name": "Nebula Syrup",   "category": "syrup", "color": Color(0.65, 0.30, 0.95)},
	"antimatter":    {"name": "Antimatter",     "category": "syrup", "color": Color(0.20, 0.95, 0.85)},
	"plasma_pink":   {"name": "Plasma Pink",    "category": "syrup", "color": Color(1.00, 0.35, 0.65)},
	"blackhole":     {"name": "Black Hole",     "category": "syrup", "color": Color(0.08, 0.06, 0.12)},
	"solar_gold":    {"name": "Solar Gold",     "category": "syrup", "color": Color(1.00, 0.78, 0.20)},

	# --- Toppings (go on last) ---
	"star_foam":     {"name": "Star Foam",      "category": "topping", "color": Color(0.95, 0.95, 1.00)},
	"stardust":      {"name": "Stardust",       "category": "topping", "color": Color(0.85, 0.80, 1.00)},
	"meteor_bits":   {"name": "Meteor Bits",    "category": "topping", "color": Color(0.55, 0.45, 0.40)},
	"glow_sprinkle": {"name": "Glow Sprinkles", "category": "topping", "color": Color(0.40, 1.00, 0.60)},
	"cherry_nova":   {"name": "Cherry Nova",    "category": "topping", "color": Color(1.00, 0.20, 0.30)},
}

# ---------------------------------------------------------------------------
# PROCESS TYPES
# The "process" step is the timing minigame between building and finishing.
# duration = seconds the meter takes to fill; the sweet-spot band is where
# a perfect result is scored.
# ---------------------------------------------------------------------------
const PROCESSES := {
	"brew":   {"name": "Brewing",  "duration": 3.0, "sweet_start": 0.60, "sweet_end": 0.85, "color": Color(0.80, 0.45, 0.20)},
	"freeze": {"name": "Freezing", "duration": 2.5, "sweet_start": 0.55, "sweet_end": 0.80, "color": Color(0.45, 0.80, 1.00)},
	"bake":   {"name": "Baking",   "duration": 3.5, "sweet_start": 0.65, "sweet_end": 0.90, "color": Color(0.95, 0.55, 0.30)},
	"blend":  {"name": "Blending", "duration": 2.0, "sweet_start": 0.50, "sweet_end": 0.78, "color": Color(0.70, 0.40, 0.90)},
}

# ---------------------------------------------------------------------------
# RECIPES  (drinks + treats)
# base_price: coins earned on a perfect serve before tips.
# steps: ordered list. "build" ingredients must be added in this order.
#        "process" is the minigame. "finish" toppings are added after.
# unlock_level: player level at which this recipe appears.
# ---------------------------------------------------------------------------
const RECIPES := {
	"nebula_nitro": {
		"name": "Nebula Nitro Brew",
		"type": "drink",
		"base_price": 12,
		"unlock_level": 1,
		"build":   ["cold_brew", "nebula_syrup"],
		"process": "brew",
		"finish":  ["star_foam"],
	},
	"galaxy_slush": {
		"name": "Galaxy Slush",
		"type": "drink",
		"base_price": 14,
		"unlock_level": 1,
		"build":   ["slush_ice", "plasma_pink"],
		"process": "freeze",
		"finish":  ["stardust"],
	},
	"blackhole_espresso": {
		"name": "Black Hole Espresso",
		"type": "drink",
		"base_price": 16,
		"unlock_level": 2,
		"build":   ["espresso", "blackhole"],
		"process": "brew",
		"finish":  ["star_foam", "meteor_bits"],
	},
	"antimatter_ade": {
		"name": "Antimatter Lemonade",
		"type": "drink",
		"base_price": 15,
		"unlock_level": 2,
		"build":   ["lemonade", "antimatter"],
		"process": "blend",
		"finish":  ["glow_sprinkle"],
	},
	"comet_cocoa": {
		"name": "Comet Cocoa",
		"type": "drink",
		"base_price": 13,
		"unlock_level": 3,
		"build":   ["cocoa", "solar_gold"],
		"process": "brew",
		"finish":  ["star_foam", "cherry_nova"],
	},
	"supernova_cupcake": {
		"name": "Supernova Cupcake",
		"type": "treat",
		"base_price": 18,
		"unlock_level": 3,
		"build":   ["cocoa", "plasma_pink"],
		"process": "bake",
		"finish":  ["glow_sprinkle", "cherry_nova"],
	},
	"moon_macaron": {
		"name": "Moon Macaron",
		"type": "treat",
		"base_price": 20,
		"unlock_level": 4,
		"build":   ["lemonade", "nebula_syrup"],
		"process": "bake",
		"finish":  ["stardust"],
	},
}

# ---------------------------------------------------------------------------
# CUSTOMERS  (recurring alien regulars — drive retention)
# patience: base seconds before they leave the queue.
# tip_mult: some regulars tip better; rewards learning their preferences.
# color: placeholder body color.
# ---------------------------------------------------------------------------
const CUSTOMERS := {
	"zorptron":  {"name": "Zorptron",  "patience": 30.0, "tip_mult": 1.2, "color": Color(0.40, 0.85, 0.55)},
	"blorbix":   {"name": "Blorbix",   "patience": 24.0, "tip_mult": 1.0, "color": Color(0.55, 0.55, 0.95)},
	"nebulina":  {"name": "Nebulina",  "patience": 35.0, "tip_mult": 1.4, "color": Color(0.90, 0.50, 0.80)},
	"quark":     {"name": "Quark",     "patience": 20.0, "tip_mult": 0.9, "color": Color(0.95, 0.70, 0.35)},
	"cosmo":     {"name": "Cosmo",     "patience": 28.0, "tip_mult": 1.1, "color": Color(0.50, 0.80, 0.90)},
}

# --- Helper lookups -------------------------------------------------------

func get_recipe(id: String) -> Dictionary:
	return RECIPES.get(id, {})

func get_ingredient(id: String) -> Dictionary:
	return INGREDIENTS.get(id, {})

func get_process(id: String) -> Dictionary:
	return PROCESSES.get(id, {})

func get_customer(id: String) -> Dictionary:
	return CUSTOMERS.get(id, {})

## Returns the full ordered ingredient list a recipe needs (build + finish),
## used to populate the ingredient shelf and to validate a served order.
func recipe_all_ingredients(id: String) -> Array:
	var r := get_recipe(id)
	if r.is_empty():
		return []
	var out: Array = []
	out.append_array(r.get("build", []))
	out.append_array(r.get("finish", []))
	return out

## All recipe ids unlocked at or below a given player level.
func recipes_for_level(level: int) -> Array:
	var out: Array = []
	for id in RECIPES:
		if int(RECIPES[id].get("unlock_level", 1)) <= level:
			out.append(id)
	return out

func customer_ids() -> Array:
	return CUSTOMERS.keys()
