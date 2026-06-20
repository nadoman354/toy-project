# Godot Architecture Ownership Plan

## Scope

This document defines ownership for the current Godot prototype while it is gradually moved toward maintainable Godot architecture. It is not a rewrite plan. Each extraction must be a separate verified goal, and runtime behavior must stay aligned with `Docs/Specs/HtmlParitySpec.md`.

Active entry path:

- `project.godot` runs `res://scenes/main/Main.tscn`.
- `scenes/main/Main.tscn` uses `scripts/v2/prototype_game.gd` as `GameRoot`.
- Active layer scripts are `scripts/v2/prototype_world.gd`, `scripts/v2/prototype_hud.gd`, `scripts/v2/prototype_popup_layer.gd`, `scripts/ui/modal/prototype_modal_layer.gd`, and `scripts/debug/prototype_debug_layer.gd`.
- Active support scripts are `scripts/v2/prototype_state.gd`, `scripts/v2/input_controller.gd`, `scripts/data/data_registry.gd`, `scripts/systems/run_coordinator.gd`, `scripts/systems/popup_close_policy.gd`, and `scripts/ui/html_layout_metrics.gd`.

Legacy or inactive paths:

- `scripts/game_root.gd`, `scripts/hud_layer.gd`, `scripts/popup_layer.gd`, `scripts/world_2d.gd`, and `scripts/data/game_data.gd` are not the active `project.godot` main path.
- `scenes/main.tscn` is not the active configured main scene. Do not add new behavior there without a separate cleanup/migration goal.
- Legacy files should not be deleted in this phase. Mark them inactive and remove them only under a future cleanup goal with a parse/smoke verification.

## Ownership Rules

- `PrototypeGame` remains the temporary coordinator, but new large behavior should not default to more monolith code.
- A future extraction is valid only if it preserves the public runtime contract proven by the existing probes.
- UI scenes own presentation and input widgets; gameplay systems own state mutation and rules.
- `HtmlLayoutMetrics` owns HTML-derived layout constants. HUD, modal, popup, and debug views should call it instead of adding new scattered layout numbers.
- `PrototypeState` owns state creation only. Future systems may read/write the shared dictionary until a later typed state migration, but they must document the keys they mutate.
- `RunCoordinator` owns tick order, pause handling, time scale clamping, and post-update view sync.
- New debug probes belong under `scripts/debug/` and `scenes/debug/`; they should target the smallest goal-specific contract.

## Current And Future Owners

| Area | Current owner | Current responsibility | Future owner | Extraction note |
| --- | --- | --- | --- | --- |
| GameRoot | `scripts/v2/prototype_game.gd`, `scenes/main/Main.tscn` | Loads data, creates layers, owns domain functions, exposes UI callbacks | `GameRoot` scene/script | Keep as scene wiring and system composition only. Move domain logic out in phases. |
| RunCoordinator | `scripts/systems/run_coordinator.gd` | Calls input shortcuts, `update_game`, visual timers, popup/HUD/world sync | `RunCoordinator` | Keep. Add explicit subsystem tick calls as systems are extracted. |
| State ownership | `scripts/v2/prototype_state.gd` plus dictionary mutations in `PrototypeGame` | Creates initial run dictionary and nested state structures | `RunState` or `PrototypeState` plus typed accessors | Defer typed migration until behavior parity is stable. First document keys per system. |
| Input | `scripts/v2/input_controller.gd`, `PrototypeGame.debug_action` | Movement vector, shortcuts, mobile fallback click state, debug action routing | `InputController`, `DebugCommandSystem` | Keep movement/shortcut logic separate. Split debug commands only after gameplay systems exist. |
| CombatSystem | `PrototypeGame.update_auto_attack`, `trigger_module_attack`, projectile/mine/turret/field/damage helpers | Attack timers, module forms, damage, projectiles, mines, turrets, fields, crit feedback | `scripts/systems/combat_system.gd` | Extract after G9-style combat probe is stable. Start with pure damage/projectile functions before moving timers. |
| EnemySystem | `PrototypeGame.update_enemies`, `spawn_enemy`, `spawn_position_for_wave`, boss spawn helpers | Enemy spawn, chase, contact damage, wave spawn positions, boss scheduling | `scripts/systems/enemy_system.gd` | Move normal enemy spawn/chase first, then boss scheduling/reward bridge after popup and reward tests exist. |
| PickupSystem | `PrototypeGame.spawn_field_pickup`, `spawn_special_consumable_drop`, `update_pickups`, `collect_pickup` | Gold/XP/heal/magnet drops, attraction, collection, pickup range | `scripts/systems/pickup_system.gd` | Extract after pickup attraction/collection probe remains green. It will call Economy and Progression through narrow methods. |
| EconomySystem | `PrototypeGame.add_gold`, credit/debt/investment/stock helpers, popup store helpers | Gold, credit score, debt, investment, stock broker, passive popup income | `scripts/systems/economy_system.gd` | Split gold/credit first. Keep stock and investment popup actions together until financial popup probes are broad enough. |
| ItemSystem | `PrototypeGame.roll_item`, `choose_item_options`, `apply_item_reward`, inventory summary helpers | Item rolls, weighted selection, item effects, inventory counts | `scripts/systems/item_system.gd` | Extract selection/reward application together. Do not move data to Resources in this phase. |
| ProgressionSystem | `PrototypeGame.add_xp`, `check_level_up`, `open_level_choice`, module/form/mechanic/scaling choice functions | XP, level gates, mastery, attack module/form/mechanic/scaling choices | `scripts/systems/progression_system.gd` | Keep choice presentation outside the system. System decides which choice is needed and applies selected rewards. |
| PopupSystem | `PrototypeGame.create_popup`, popup runtime state, popup scheduling, close/reward actions, `PopupClosePolicy` | Popup definitions, runtime state, timers, close policies, rewards, special popup rules | `scripts/systems/popup_system.gd` plus `PopupClosePolicy` | `PrototypePopupLayer` should remain view-only. Move policy/state decisions before moving popup rendering. |
| ChoiceSystem | `PrototypeHud.show_choices`, `show_boss_package_choices`, selection flags in state, callbacks in `PrototypeGame` | Builds item/perk/module/boss choice overlays and dispatches callbacks | `scripts/systems/choice_system.gd` plus `PrototypeModalLayer` | Future owner should model choice sessions. HUD/modal renders a session and emits selection events. |
| HUD view | `scripts/v2/prototype_hud.gd`, `scenes/layers/HudLayer.tscn` | HUD panels, item/choice cards, inventory overlay, debug HUD, mobile controls | `PrototypeHud` scene/script | Keep as presentation. It may format text from state but should not decide gameplay outcomes. |
| Modal view | `scripts/ui/modal/prototype_modal_layer.gd`, `scenes/ui/modal/ChoiceOverlay.tscn` | Provides high z-order parent for choice overlay | `PrototypeModalLayer` | Keep small. ChoiceSystem should request sessions; modal layer should only host controls. |
| Popup view | `scripts/v2/prototype_popup_layer.gd`, `scenes/ui/popup/PopupWindow.tscn` | Creates popup windows, drag/minimize/close UI, syncs from popup state | `PrototypePopupLayer` | Keep as view/input adapter. Gameplay actions should route to PopupSystem/GameRoot methods. |
| World view | `scripts/v2/prototype_world.gd`, `scenes/layers/WorldLayer.tscn` | Draws background, player, enemies, pickups, attacks, projectiles, particles | `PrototypeWorld` | Keep rendering-only. Do not put combat or spawn logic here. |
| Data | `scripts/data/prototype_data.json`, `scripts/data/data_registry.gd` | JSON source of config, items, popups, modules, perks | `DataRegistry` | Keep JSON during this phase. Add validation before any Resource migration. |
| Verification | `scripts/debug/*`, `scenes/debug/*`, `scripts/v2/prototype_smoke_cli.gd`, `scripts/v2/prototype_smoke_runner.gd` | Goal-specific probes and broad smoke scenarios | Debug/verification scripts | Each extracted system must either reuse an existing probe or add a focused one. |

## Extraction Phases

Phase 0: Stabilize contracts.

- Keep current runtime structure.
- Maintain `HtmlParitySpec`, audit, goals, and probes.
- Add new behavior only when it has a goal-specific verification path.

Phase 1: Add subsystem shells without behavior changes.

- Create small RefCounted systems with explicit `game` or `state` references.
- Move pure helper groups first when tests cover them.
- Keep public method names on `PrototypeGame` as adapters so UI callbacks and probes do not break.

Phase 2: Separate view ownership from rule ownership.

- Ensure HUD, modal, popup, and world scripts are view/input adapters.
- Route gameplay decisions through `PrototypeGame` adapters or new systems.
- Keep layout constants in `HtmlLayoutMetrics`.

Phase 3: Extract choice and progression.

- Move level gate decisions and reward application into `ProgressionSystem`.
- Introduce a choice session shape for item/perk/module/boss choices.
- Let HUD/modal render sessions without owning progression rules.

Phase 4: Extract core loop systems.

- Move pickup attraction/collection into `PickupSystem`.
- Move enemy spawn/chase/contact into `EnemySystem`.
- Move attack timers, damage, projectiles, mines, turrets, fields, and crit feedback into `CombatSystem`.
- Keep the G9 core loop probe green after each small move.

Phase 5: Extract economy, item, and popup actions.

- Move gold/credit/debt/stock/investment rules into `EconomySystem`.
- Move item roll, weighted choice, and item reward application into `ItemSystem`.
- Move popup runtime state, scheduling, reward resolution, and special popup effects into `PopupSystem`.
- Keep `PrototypePopupLayer` rendering-only.

Phase 6: Type state after behavior is stable.

- Replace broad dictionary mutation only after systems have clear key ownership.
- Introduce typed state/accessors behind adapters.
- Do not convert `prototype_data.json` to Resources until data validation and parity probes exist.

## Future Goal Rules

- A goal that touches gameplay must name the future owner even if the code remains in `PrototypeGame` temporarily.
- A goal that adds UI must state whether the change belongs to HUD, modal, popup, debug, or world view.
- A goal that changes layout must cite `HtmlLayoutMetrics` or explain why the value is local.
- A goal that changes shared state must list the mutated state keys in its verification notes.
- A goal that moves code must run the relevant existing probe before and after the move.

## Verification For This Plan

File-level review checklist:

- GameRoot and RunCoordinator ownership are covered.
- State ownership is covered.
- Combat, enemy, pickup, economy, item, progression, popup, and choice systems are covered.
- HUD, modal, popup, world, data, input, and verification ownership are covered.
- Active vs legacy scripts are documented.
- Extraction phases avoid a full rewrite and preserve goal-by-goal verification.
