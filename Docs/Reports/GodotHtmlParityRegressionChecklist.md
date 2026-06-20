# Godot HTML Parity Regression Checklist

## Purpose

Use this checklist for future Godot parity goals. It does not replace a goal's acceptance criteria. It defines the repeatable checks that should be selected based on the files and behavior touched by that goal.

Run commands from the repository root:

`C:\Users\nadom\Documents\toy-project`

Godot executable used for the current probes:

`C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe`

Use `--log-file tmp\<name>.log` for every headless run. Godot print output is more reliable in the log file than in PowerShell stdout.

## Required Failure Rule

- Do not mark a goal `[x]` when its required subset fails.
- If Godot cannot run, mark runtime verification as blocked or file-level only. Leave the goal unchecked or `[~]` unless the goal can truly be proven without runtime.
- When a check fails, record the failed command, inspect the log, make the smallest fix, and rerun the failed check plus any adjacent impacted checks.
- Do not use the broad smoke result as a substitute for goal-specific acceptance.

## Probe Commands

| Check | Covers | Command | Pass signal |
| --- | --- | --- | --- |
| G1 input | Item machine, inventory, choice cards, popup close/content buttons, debug buttons, hidden overlay pass-through, modal blocking | `& 'C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe' --headless --path . --log-file tmp\g1_input_probe_scene.log --scene res://scenes/debug/G1InputProbe.tscn` | `g1_input_probe passed` |
| G2 viewport | Main scene, full viewport roots, no fixed board shortcut, world background fill | `& 'C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe' --headless --path . --log-file tmp\g2_viewport_probe.log --scene res://scenes/debug/G2ViewportProbe.tscn` | `g2_viewport_probe passed` |
| G3 layout service | `HtmlLayoutMetrics`, HUD constants, choice panel constants, popup size lookup, caller rects | `& 'C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe' --headless --path . --log-file tmp\g3_layout_service_probe.log --scene res://scenes/debug/G3LayoutServiceProbe.tscn` | `g3_layout_service_probe passed` |
| G4 text | Korean wrapping, title ellipsis, HUD labels, choice text, popup title/body/detail/status text | `& 'C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe' --headless --path . --log-file tmp\g4_text_contract_probe.log --scene res://scenes/debug/G4TextContractProbe.tscn` | `g4_text_contract_probe passed` |
| G5 HUD | 960x540 and 1152x648 HUD layout, panel padding/radius, centered difficulty HUD, input pass-through | `& 'C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe' --headless --path . --log-file tmp\g5_hud_probe.log --scene res://scenes/debug/G5HudProbe.tscn` | `g5_hud_probe passed` |
| G6 choice/modal | Initial module choice, item choice, boss package choice, inventory overlay, modal z-order, hidden pass-through | `& 'C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe' --headless --path . --log-file tmp\g6_choice_modal_probe.log --scene res://scenes/debug/G6ChoiceModalProbe.tscn` | `g6_choice_modal_probe passed` |
| G7 popup | Popup size table, clamp, click-to-front, drag release anywhere, close/minimize/forced close policies | `& 'C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe' --headless --path . --log-file tmp\g7_popup_probe.log --scene res://scenes/debug/G7PopupProbe.tscn` | `g7_popup_probe passed` |
| G8 progression | Primary/secondary/module/form/mechanic gates, default advanced gate, automatic mastery, level-up pause behavior | `& 'C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe' --headless --path . --log-file tmp\g8_progression_probe.log --scene res://scenes/debug/G8ProgressionProbe.tscn` | `g8_progression_probe passed` |
| G9 core loop | Player/layers, enemy spawn/chase, auto attack, kill/drop, pickup attraction/collection, HUD update, item machine, popup, boss package | `& 'C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe' --headless --path . --log-file tmp\g9_core_loop_probe.log --scene res://scenes/debug/G9CoreLoopProbe.tscn` | `g9_core_loop_probe passed` |
| Scene smoke | Basic integrated runtime scenario through `scenes/prototype_smoke_test.tscn` | `& 'C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe' --headless --path . --log-file tmp\prototype_smoke_test.log --scene res://scenes/prototype_smoke_test.tscn` | exit code `0`, result JSON exists, `has_primary_module=true`, `first_purchase_paid=true`, `has_hud=true`, `has_popup_layer=true` |
| CLI smoke | Extended popup/economy/combat/item/security/stock/boss package scenario through `prototype_smoke_cli.gd` | `& 'C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe' --headless --path . --log-file tmp\prototype_smoke_cli.log --script scripts/v2/prototype_smoke_cli.gd` | result JSON exists and key booleans are true |

## Syntax And Parse Check

There is no separate standalone parser command required by this workflow. A headless Godot scene or script run parses the loaded scene, referenced scripts, preloads, and typed GDScript before the pass signal can appear.

Use this rule:

- Script-only change: run the smallest probe that preloads the changed script.
- Scene or layer wiring change: run G2 and scene smoke.
- Shared UI script change: run the affected UI probe plus G1.
- Shared gameplay script change: run G9 and CLI smoke.
- Any parse error, preload error, missing node error, or non-zero exit code is a failed syntax/parse check.

Smoke result JSON path:

`C:\Users\nadom\AppData\Roaming\Godot\app_userdata\ToyProject\prototype_smoke_result.json`

Minimum CLI smoke fields to check:

- `has_primary_module=true`
- `first_purchase_paid=true`
- `boss_package_two_pick_flow_exercised=true`
- `all_popup_definitions_createable=true`
- `all_items_apply_without_error=true`
- `has_hud=true`
- `has_popup_layer=true`
- `kill_count > 0`

## Goal-To-Check Map

| Change area | Required checks |
| --- | --- |
| Project launch, scene wiring, root layers | G2, scene smoke |
| Button/input, overlays, mouse filtering, CanvasLayer order | G1, G6, G7 when popups are touched |
| Viewport, full-screen roots, world fill | G2, G5 |
| Layout constants or `HtmlLayoutMetrics` | G3, plus G5/G6/G7 for the affected UI |
| Korean text, labels, wrapping, card copy | G4, plus affected UI probe |
| HUD panels, status/debug/mobile HUD controls | G5, G1 |
| Choice overlay, item/perk/module/boss package choices | G6, G1, G8 when level choices are touched |
| Popup rendering, z-order, drag, close/minimize policy | G7, G1, CLI smoke for popup actions |
| Progression, XP, level gates, module/form/mechanic/mastery | G8, G6 |
| Combat, enemies, pickups, item machine, boss rewards | G9, CLI smoke |
| Economy, items, financial popups, stock, store, first purchase | CLI smoke, G7, G6 if choices are touched |
| Architecture-only documentation | File-level review only; no runtime required unless code moved |
| Verification infrastructure | File-level review and at least one dry-run probe |

## Viewport Checklist

Use automated probes first:

- 960x540: G2, G3, G4, G5, G6.
- 1152x648: G2, G4, G5, G6.
- Wider desktop: G2 and G6 use 1920x1080 paths; G7 popup clamp uses a wide viewport.
- Mobile/narrow layout: G4 and G6 include compact/mobile text and choice checks.

Manual viewport smoke is only needed when the changed UI is not covered by a probe. In that case, launch the main scene and check:

- No large black fixed-board margins.
- World/background fills the visible viewport.
- HUD panels match HTML proportions and do not block popup/modal input.
- Modal appears above popups.
- Popup layer appears above HUD and below modal.
- Text does not wrap one Korean character per line.

## Button And Input Checklist

Automated checks: G1, G6, G7.

Manual fallback:

- Item machine button opens item choices.
- Inventory button opens inventory overlay.
- Choice cards are clickable.
- Popup title close button works where policy allows.
- Popup content buttons work after input grace.
- Debug buttons respond.
- Hidden choice/game-over overlays do not block clicks.
- Visible modal blocks world input but not its own controls.

## Modal And Choice Checklist

Automated checks: G6, G8, G9 for item machine and boss package.

Manual fallback:

- Initial primary module choice is readable and clickable.
- Item choices use desktop columns and compact/mobile fallback.
- Boss package choice allows two selections and resumes after completion.
- Modal parent is `ModalLayer`, above popup and HUD layers.
- Hiding the modal restores `MOUSE_FILTER_IGNORE`.

## Popup Checklist

Automated checks: G7 and CLI smoke.

Manual fallback:

- Popup size matches `Docs/Specs/HtmlParitySpec.md`.
- Popup clamps inside viewport.
- Drag starts from title bar and release anywhere stops drag.
- Clicking any popup content brings it forward.
- Stock broker app minimizes instead of closing.
- Forced-choice popups cannot be closed through normal close.
- Popup content buttons respect input grace and disabled state.

## Progression Checklist

Automated check: G8.

Manual fallback:

- Primary module selection opens at run start.
- Secondary module opens at level 5.
- Attack form opens at level 9.
- Attack mechanic opens at level 13.
- Advanced build/deepening/synergy choices stay gated by default.
- Non-special level-ups apply automatic mastery without opening an unrelated modal.

## Core Loop Checklist

Automated checks: G9 and CLI smoke.

Manual fallback:

- Player appears and can move.
- Enemy spawns outside the player area and chases.
- Auto attack starts after module selection.
- Enemy death creates gold and XP drops.
- Pickups inside pickup range move toward the player and collect only near the player.
- HUD gold/HP/XP changes after collection.
- Item machine spends gold and opens choices.
- Popups spawn and remain interactive.
- Boss death opens boss package flow if boss is implemented.

## If Godot Cannot Run

- Record the exact command that failed to launch and the environment symptom.
- Do file-level verification only: inspect changed scripts, scene references, docs, and data.
- Leave runtime acceptance unchecked or `[~]` unless the goal is documentation-only.
- Add a follow-up note that the first next pass must rerun the blocked probe before continuing.

## Current Dry-Run Record

G11 dry-run executed with Godot 4.7:

- G1 through G9 scene probes: all passed.
- Scene smoke: passed.
- CLI smoke: passed with `has_primary_module=true`, `first_purchase_paid=true`, `boss_package_two_pick_flow_exercised=true`, `all_popup_definitions_createable=true`, `all_items_apply_without_error=true`, `has_hud=true`, `has_popup_layer=true`, and `kill_count=4`.
