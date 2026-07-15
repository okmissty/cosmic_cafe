# Cosmic Café — Godot 4 Project

A space-themed, Papa's-style time-management café game. Serve galactic drinks
and sweet treats to alien customers through a build → process → finish → serve
loop. Fully playable with placeholder art (colored shapes) — no image assets
required to run.

## Requirements
- Godot 4.3 or newer (stable).

## How to run
1. Open Godot → Import → select this folder's `project.godot`.
2. Press Play (F5). Main scene is `scenes/Main.tscn`.

## Controls / flow
- Main menu → START SHIFT.
- Tap a customer ticket to begin their order.
- BUILD: tap ingredients in the order shown (dark chips = not yet added).
- ▶ Process: tap to stop the meter inside the green sweet-spot band.
- FINISH: add toppings, then ✅ SERVE.
- Accuracy + leftover patience (speed) = coins + tips. Shift lasts 90s.
- End screen shows score, a rewarded-ad "2x coins" hook, and replay.

## Architecture
- `scripts/GameData.gd`  (autoload) — ALL content: ingredients, recipes,
  processes, customers. Add a drink/treat by adding one RECIPES entry.
- `scripts/GameState.gd` (autoload) — persistent coins/gems/level/XP + JSON save.
- `scripts/Order.gd`        — one order's state + accuracy/reward scoring.
- `scripts/ShiftManager.gd` — spawns customers, runs the clock, totals score.
- `scripts/ProcessMeter.gd` — the timing minigame widget.
- `scripts/PlaceholderArt.gd` — draws colored cups/cupcakes/chips as stand-ins.
- `scripts/PlayScene.gd`   — gameplay screen (stations, shelf, tickets, UI).
- `scripts/MainMenu.gd` / `ShiftResults.gd` — menu and end-of-shift screens.

## Where to plug in the money (later)
- Rewarded ad: `ShiftResults.gd`, the bonus button `pressed` callback.
- Remove-ads IAP: `MainMenu.gd` "Remove Ads" button → set `GameState.ads_removed = true`.
- Shop / cosmetics: `MainMenu.gd` shop button; store purchases via
  `GameState.own_cosmetic(id)`, spend with `spend_coins` / `spend_gems`.

## Swapping in real art
Replace `PlaceholderArt` nodes with `TextureRect`s pointing at
`assets/sprites/...`. Ingredient colors live in `GameData.INGREDIENTS`.

## Balancing knobs
- `ShiftManager`: `shift_duration`, `max_queue`, `spawn_interval`.
- `GameData.PROCESSES`: sweet-spot width/position per process.
- `GameData.RECIPES`: base_price, steps, unlock_level.
- `GameState.XP_CURVE`: level pacing.
