# Godot HTML Parity Goals

Purpose: 현재 Godot 구현을 HTML prototype과 맞추되, 한 번에 전체를 고치지 않고 작은 검증 가능한 목표로 진행하기 위한 순차 checklist다.

Source documents:
- `Docs/Specs/HtmlParitySpec.md`
- `Docs/Reports/GodotVsHtmlAudit.md`

Rules:
- Work only on the first goal with status `[ ]` or `[~]`.
- Do not skip ahead.
- Do not combine goals unless the audit proves they are inseparable.
- Do not mark `[x]` without verification evidence.
- If Godot cannot be run, mark verification as file-level only and leave implementation goals `[ ]` or `[~]` unless acceptance can truly be proven.
- Stop after one goal. Do not continue into the next goal without explicit user approval.

Allowed statuses:
- `[ ]` not started
- `[~]` in progress or blocked
- `[x]` verified complete

Future pass protocol:
1. Read `Docs/Specs/HtmlParitySpec.md`.
2. Read `Docs/Reports/GodotVsHtmlAudit.md`.
3. Read this file.
4. Select only the first `[ ]` or `[~]` goal.
5. Restate the current goal.
6. Inspect only relevant files.
7. Identify likely cause.
8. Implement the smallest safe change.
9. Verify using that goal's acceptance criteria.
10. Update status only if verified.
11. Stop.
12. Report the next recommended goal.

## G0. HTML parity spec and Godot audit

Status: [x]
Category: Documentation / strategy
Priority: P0
Depends on: None
Scope:
- Create or update the HTML parity spec, Godot-vs-HTML audit, and this sequential goals checklist.
- Inspect the current Godot implementation, HTML reference, active scenes, data, existing verification scripts, and docs state.
Do:
- Extract explicit HTML behavior and layout constants.
- Categorize current Godot mismatches.
- Keep goals small and ordered.
Do not:
- Modify runtime gameplay code.
- Claim implementation goals complete.
- Rewrite the game.
Likely files:
- `Docs/Specs/HtmlParitySpec.md`
- `Docs/Reports/GodotVsHtmlAudit.md`
- `Docs/ActiveTasks/GodotHtmlParityGoals.md`
Acceptance criteria:
- HTML reference rules are explicit and Godot-applicable.
- Current Godot mismatches are categorized with suggested fix and verification method.
- Goals are ordered and small enough to execute one at a time.
Verification:
- File-level verification: all three docs exist and include required sections.
- No runtime code changes are part of G0.
Rollback notes:
- Remove only the three G0 docs if the goals workflow needs to be discarded.

## G1. Button/input blocking fix

Status: [x]
Category: Input / interaction
Priority: P0
Depends on: G0
Scope:
- Make every expected UI button reliably clickable without changing gameplay balance.
Do:
- Investigate `mouse_filter`, `CanvasLayer` order, hidden overlays, full-screen roots, child Controls inside Buttons, disabled state, modal overlays, popup input grace, and mobile fallback click behavior.
- If unclear, temporarily log hovered control path, mouse_filter, visible state, disabled state, parent chain, CanvasLayer, and rect.
- Remove or gate diagnostics after use.
Do not:
- Change progression, economy, popup content, or layout dimensions except where required for input.
- Leave hidden overlays blocking input.
Likely files:
- `scripts/v2/prototype_hud.gd`
- `scripts/v2/prototype_popup_layer.gd`
- `scripts/v2/input_controller.gd`
- `scripts/ui/modal/prototype_modal_layer.gd`
- `scripts/debug/g1_input_probe_cli.gd`
- `scenes/debug/G1InputProbe.tscn`
- `scenes/ui/modal/ChoiceOverlay.tscn`
- `scenes/ui/cards/ChoiceCard.tscn`
Acceptance criteria:
- Item machine button clickable when enabled and enough gold exists.
- Inventory button clickable when allowed.
- Choice cards clickable.
- Popup close button clickable.
- Popup content buttons clickable.
- Debug buttons clickable.
- Hidden overlays do not block input.
- Visible modal blocks world input but not its own buttons.
Verification:
- Runtime scene probe added and run with Godot 4.7:
  `C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe --headless --path . --log-file tmp\g1_input_probe_scene.log --scene res://scenes/debug/G1InputProbe.tscn`
- Result: `g1_input_probe passed`.
- Probe covers item machine, inventory, choice card callbacks, popup title close, popup content buttons, popup input grace, debug buttons, hidden overlay pass-through, visible choice modal blocking, layer order, and mobile button/root mouse filters.
Rollback notes:
- Revert only input policy/diagnostic changes from this goal.

## G2. Viewport fill / fixed board removal

Status: [x]
Category: Viewport / world rendering
Priority: P0
Depends on: G1
Scope:
- Ensure world and UI fill the actual viewport like HTML.
Do:
- Verify `project.godot`, main scene, layer roots, world draw, camera, and viewport resizing.
- Remove any remaining fixed 960x540 board behavior.
Do not:
- Solve by scaling the entire UI root.
- Introduce a fixed AspectRatioContainer for the whole game.
Likely files:
- `project.godot`
- `scenes/main/Main.tscn`
- `scenes/layers/*.tscn`
- `scripts/v2/prototype_world.gd`
- `scripts/v2/prototype_game.gd`
- `scripts/ui/html_layout_metrics.gd`
- `scripts/debug/g2_viewport_probe.gd`
- `scenes/debug/G2ViewportProbe.tscn`
Acceptance criteria:
- No large black margins around a centered fixed board.
- World/background/grid fills visible viewport.
- UI roots are full viewport.
- No global fixed 960x540 board scaling shortcut.
Verification:
- Runtime scene probe added and run with Godot 4.7:
  `C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe --headless --path . --log-file tmp\g2_viewport_probe.log --scene res://scenes/debug/G2ViewportProbe.tscn`
- Result: `g2_viewport_probe passed`.
- Probe covers project stretch settings, absence of fixed-board containers, and world/HUD/popup/debug/modal roots filling `960x540`, `1152x648`, `1920x1080`, and `2340x1080`.
Rollback notes:
- Revert only viewport/root layout changes.

## G3. CSS-like LayoutService

Status: [x]
Category: Architecture / UI layout
Priority: P1
Depends on: G2
Scope:
- Make a real Godot helper that translates HTML/CSS layout rules into reusable Control rects.
Do:
- Use or repair `scripts/ui/html_layout_metrics.gd` or equivalent.
- Provide viewport size, top-left, top-right, bottom-left, bottom-right, top-center, center panel, choice panel size, difficulty HUD width, and popup size lookup.
- Move feasible HUD/modal/popup layout code to this service.
Do not:
- Treat the existing helper as complete until it matches `HtmlParitySpec`.
- Pass by changing scattered magic numbers only.
Likely files:
- `scripts/ui/html_layout_metrics.gd`
- `scripts/v2/prototype_hud.gd`
- `scripts/v2/prototype_popup_layer.gd`
- `scripts/debug/layout_probe_cli.gd`
- `scripts/debug/g3_layout_service_probe.gd`
- `scenes/debug/G3LayoutServiceProbe.tscn`
Acceptance criteria:
- HUD/modal/popup layout code uses the service where feasible.
- Service returns HTML spec constants for HUD, choice panel, and popup sizes.
- If the diff only tweaks numbers inside existing HUD code, the goal is failed.
Verification:
- Runtime scene probe added and run with Godot 4.7:
  `C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe --headless --path . --log-file tmp\g3_layout_service_probe.log --scene res://scenes/debug/G3LayoutServiceProbe.tscn`
- Result: `g3_layout_service_probe passed`.
- Probe compares placement helpers, HUD constants, choice panel constants, popup size table, `PrototypeGame.popup_size_for()`, and HUD/choice caller rects against `HtmlParitySpec`.
- Regression probes rerun after the service change: `g1_input_probe passed`, `g2_viewport_probe passed`.
Rollback notes:
- Revert helper changes and callers changed in this goal only.

## G4. Text wrapping fix

Status: [x]
Category: Text / UI readability
Priority: P1
Depends on: G3
Scope:
- Stop Korean one-character wrapping while preserving readable body text.
Do:
- Set default labels to no autowrap.
- Trim/ellipsis title labels.
- Keep HUD labels single-line.
- Allow body/description labels to wrap only inside stable-width containers.
- Keep choice card widths stable.
Do not:
- Disable all wrapping everywhere.
- Hide body descriptions without a readable alternative.
Likely files:
- `scripts/v2/prototype_hud.gd`
- `scripts/v2/prototype_popup_layer.gd`
- `scripts/ui/html_layout_metrics.gd`
- `scenes/ui/cards/ChoiceCard.tscn`
- `scripts/debug/g4_text_contract_probe.gd`
- `scenes/debug/G4TextContractProbe.tscn`
Acceptance criteria:
- Korean text no longer appears one character per line.
- Default labels do not autowrap.
- Title labels trim/ellipsis.
- Small HUD labels do not wrap.
- Body/description labels wrap only in stable-width containers.
- Choice cards have stable width.
Verification:
- Runtime scene probe added and run with Godot 4.7:
  `C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe --headless --path . --log-file tmp\g4_text_contract_probe.log --scene res://scenes/debug/G4TextContractProbe.tscn`
- Result: `g4_text_contract_probe passed`.
- Probe covers HUD labels/RichText, choice overlay title/description, choice card title/body/meta/tag labels, popup title/body/detail/buttons/status badges at `960x540`, `1152x648`, and `390x844`.
- Regression probes rerun after text changes: `g1_input_probe passed`, `g3_layout_service_probe passed`.
Rollback notes:
- Revert text contract changes only.

## G5. HUD HTML parity

Status: [x]
Category: HUD layout
Priority: P1
Depends on: G4
Scope:
- Match desktop HTML HUD layout proportions.
Do:
- Apply spec constants for combat, economy, difficulty, cleanup, status, and debug HUD.
- Preserve input pass-through outside actual controls.
Do not:
- Oversize or squeeze HUD panels to fit unrelated content.
- Let HUD root block popup or modal input.
Likely files:
- `scripts/ui/html_layout_metrics.gd`
- `scripts/v2/prototype_hud.gd`
- `scenes/layers/HudLayer.tscn`
- `scenes/layers/DebugLayer.tscn`
- `scripts/debug/g5_hud_probe.gd`
- `scenes/debug/G5HudProbe.tscn`
Acceptance criteria:
- At `960x540` and `1152x648`, HUD visually matches HTML proportions.
- `combatHud`: top `12`, left `12`, width `270`.
- `economyHud`: top `12`, right `12`, width `255`.
- `difficultyHud`: top `10`, centered, width `min(340, viewport_width - 520)`, min `240`.
- `statusPanel`: left `12`, bottom `12`, width about `270`.
- `debugPanel`: right `12`, bottom `12`, width about `250`.
- HUD root does not block popup or modal input.
Verification:
- Runtime scene probe added and run with Godot 4.7:
  `C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe --headless --path . --log-file tmp\g5_hud_probe.log --scene res://scenes/debug/G5HudProbe.tscn`
- Result: `g5_hud_probe passed`.
- Probe covers desktop HUD rects, margins, centered difficulty HUD, `12px` panel padding, `8px` radius, and HUD input pass-through at `960x540` and `1152x648`.
- Regression probes rerun after HUD padding change: `g3_layout_service_probe passed`, `g4_text_contract_probe passed`.
Rollback notes:
- Revert HUD layout/helper changes only.

## G6. Choice/modal HTML parity

Status: [x]
Category: Modal / choice UI
Priority: P1
Depends on: G5
Scope:
- Match HTML item/perk/module/paid-choice overlays.
Do:
- Use full-screen dark overlay above popups.
- Center panel with HTML width/max-height rules.
- Match desktop 3-column grid and gap.
- Make cards readable and clickable.
Do not:
- Keep hidden modal input-blocking.
- Use a 900px large-desktop choice panel unless explicitly approved.
Likely files:
- `scripts/v2/prototype_hud.gd`
- `scripts/ui/html_layout_metrics.gd`
- `scripts/ui/modal/prototype_modal_layer.gd`
- `scenes/ui/modal/ChoiceOverlay.tscn`
- `scenes/ui/cards/ChoiceCard.tscn`
- `scripts/debug/g6_choice_modal_probe.gd`
- `scenes/debug/G6ChoiceModalProbe.tscn`
Acceptance criteria:
- Initial module choice readable.
- Item choices readable.
- Boss package choices readable.
- Choice cards clickable.
- Modal appears above popups.
- Hidden modal does not block input.
- Choice panel width follows `min(680, viewport_width - 40)` on desktop.
- Desktop choice grid uses 3 columns, gap `12`.
Verification:
- Runtime scene probe added and run with Godot 4.7:
  `C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe --headless --path . --log-file tmp\g6_choice_modal_probe.log --scene res://scenes/debug/G6ChoiceModalProbe.tscn`
- Result: `g6_choice_modal_probe passed`.
- Probe covers initial module, item choice, boss package, and inventory overlays at `960x540`, `1152x648`, `1920x1080`, and `390x844`; it verifies ModalLayer parenting/order, hidden overlay pass-through, panel width/centering, desktop columns/gap, compact padding/gap, and stable card sizes.
- Regression probes rerun after choice/modal changes: `g1_input_probe passed`, `g3_layout_service_probe passed`, `g4_text_contract_probe passed`, `g5_hud_probe passed`.
Rollback notes:
- Revert modal/choice layout changes only.

## G7. Popup parity

Status: [x]
Category: Popup system
Priority: P1
Depends on: G6
Scope:
- Match HTML popup size, z-order, drag, close, minimize, and layer behavior.
Do:
- Match `popupSizeFor` table from `HtmlParitySpec`.
- Clamp windows inside viewport.
- Start drag from title bar and release anywhere.
- Bring popup forward on click.
- Preserve stock broker minimize-only behavior.
- Preserve forced-choice and locked popup close policies.
Do not:
- Create one full popup scene per popup type.
- Put all special behavior into a new God Object.
Likely files:
- `scripts/ui/html_layout_metrics.gd`
- `scripts/v2/prototype_popup_layer.gd`
- `scripts/v2/prototype_game.gd`
- `scripts/systems/popup_close_policy.gd`
- `scenes/ui/popup/PopupWindow.tscn`
- `scripts/debug/g7_popup_probe.gd`
- `scenes/debug/G7PopupProbe.tscn`
Acceptance criteria:
- Popup sizes match spec table.
- Popup windows clamp inside viewport.
- Drag starts from title bar and release anywhere stops drag.
- Click brings popup forward.
- Normal close button works.
- Stock broker app minimizes instead of normal close.
- Forced-choice popups cannot be normally closed.
- Popup layer is above HUD and below Modal.
Verification:
- Runtime scene probe added and run with Godot 4.7:
  `C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe --headless --path . --log-file tmp\g7_popup_probe.log --scene res://scenes/debug/G7PopupProbe.tscn`
- Result: `g7_popup_probe passed`.
- Probe covers the full popup size table, runtime panel size, viewport clamping, click-anywhere bring-to-front, release-anywhere drag settle, stock broker minimize-only behavior, first-purchase forced close, and stock broker locked close policy.
- Regression probes rerun after popup changes: `g1_input_probe passed`, `g3_layout_service_probe passed`, `g4_text_contract_probe passed`, `g6_choice_modal_probe passed`.
Rollback notes:
- Revert popup layer/helper/policy changes only.

## G8. Progression parity

Status: [x]
Category: Progression / design behavior
Priority: P1
Depends on: G7
Scope:
- Make Godot level-up/progression match HTML reference or explicitly gate approved differences.
Do:
- Inspect HTML `handleLevelChoice`.
- Inspect Godot `open_level_choice` and related selection functions.
- Preserve data and hidden advanced options behind gates if needed.
Do not:
- Delete data.
- Enable unapproved advanced choices by default.
- Rebalance unrelated combat/economy.
Likely files:
- `scripts/v2/prototype_game.gd`
- `scripts/data/prototype_data.json`
- `scripts/v2/prototype_hud.gd`
- `scripts/debug/g8_progression_probe.gd`
- `scenes/debug/G8ProgressionProbe.tscn`
Acceptance criteria:
- Initial primary module selection works.
- Secondary module timing matches HTML `level >= 5`.
- Attack form timing matches HTML `level >= 9`.
- Attack mechanic timing matches HTML `level >= 13`.
- Build scaling timing matches HTML `level >= 17` or is explicitly gated.
- Unapproved advanced choices do not appear by default.
- Features are gated rather than deleted.
Verification:
- Runtime scene probe added and run with Godot 4.7:
  `C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe --headless --path . --log-file tmp\g8_progression_probe.log --scene res://scenes/debug/G8ProgressionProbe.tscn`
- Result: `g8_progression_probe passed`.
- Probe covers Lv.2/5/8/9/12/13/17 labels, secondary module gate, form/mechanic gates, default build-scaling gate, non-special automatic mastery without modal, and `check_level_up()` stopping when a special selection opens.
- Regression probes rerun after progression changes: `g1_input_probe passed`, `g6_choice_modal_probe passed`, `g7_popup_probe passed`.
Rollback notes:
- Revert progression gate changes only.

## G9. Core gameplay loop parity

Status: [x]
Category: Gameplay loop
Priority: P1
Depends on: G8
Scope:
- Verify and repair the minimum HTML-like combat/economy loop.
Do:
- Check player, enemy spawn/chase, auto attack, kill, gold/XP drop, pickup, HUD update, item machine, popups, boss/reward flow.
- Repair only loop behavior needed for HTML parity.
Do not:
- Rebalance the whole game.
- Add unrelated combat features.
Likely files:
- `scripts/v2/prototype_game.gd`
- `scripts/v2/prototype_world.gd`
- `scripts/v2/prototype_state.gd`
- `scripts/data/prototype_data.json`
- `scripts/v2/prototype_hud.gd`
- `scripts/v2/prototype_popup_layer.gd`
- `scripts/debug/g9_core_loop_probe.gd`
- `scenes/debug/G9CoreLoopProbe.tscn`
Acceptance criteria:
- Player appears.
- Enemy spawns.
- Enemy chases.
- Auto attack works after module selection.
- Enemy dies.
- Gold/XP drops.
- Pickups collect with HTML-like behavior.
- HUD updates.
- Item machine works.
- Popups spawn.
- Boss spawn/reward flow works if implemented.
Verification:
- Targeted runtime probe added and run with Godot 4.7:
  `C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe --headless --path . --log-file tmp\g9_core_loop_probe.log --scene res://scenes/debug/G9CoreLoopProbe.tscn`
- Result: `g9_core_loop_probe passed`.
- Probe covers player/layers, enemy spawn and chase, auto attack after primary module selection, enemy death, gold/XP drops, HTML-like pickup attraction before collection, HUD text update, item machine modal, popup window creation, boss kill reward popup, and boss package two-pick reward completion.
- Existing Godot smoke scenario also run:
  `C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe --headless --path . --log-file tmp\prototype_smoke_test.log --scene res://scenes/prototype_smoke_test.tscn`
- Smoke result JSON: `has_primary_module=true`, `kill_count=4`, `boss_package_two_pick_flow_exercised=true`, `has_hud=true`, `has_popup_layer=true`, `all_popup_definitions_createable=true`, `all_items_apply_without_error=true`.
- Automated verification covered the acceptance criteria; manual play smoke was not required for this goal.
Rollback notes:
- Revert loop changes by subsystem; do not revert data unrelated to this goal.

## G10. Structural ownership plan

Status: [x]
Category: Architecture documentation
Priority: P2
Depends on: G9
Scope:
- Document which prototype parts remain monolithic and what should be extracted later.
Do:
- Cover GameRoot/RunCoordinator, state ownership, combat, enemy, pickup, economy, item, progression, popup, choice, HUD/modal/popup scenes.
- Define phased extraction order.
Do not:
- Start a full rewrite.
- Move large systems without separate implementation goals.
Likely files:
- `Docs/Reports/GodotVsHtmlAudit.md`
- `Docs/ActiveTasks/GodotHtmlParityGoals.md`
- `Docs/Specs/GodotArchitectureOwnership.md`
Acceptance criteria:
- A realistic phased refactor plan exists.
- No full rewrite is required immediately.
- Future new code has a clear owner.
- Legacy vs active scripts are documented.
Verification:
- File-level review completed with:
  `rg -n "GameRoot|RunCoordinator|State ownership|CombatSystem|EnemySystem|PickupSystem|EconomySystem|ItemSystem|ProgressionSystem|PopupSystem|ChoiceSystem|HUD view|Modal view|Popup view|Legacy|Extraction Phases|Future Goal Rules" Docs/Specs/GodotArchitectureOwnership.md`
- Result: ownership doc covers active entry path, active vs legacy scripts, GameRoot/RunCoordinator, state, combat, enemy, pickup, economy, item, progression, popup, choice, HUD/modal/popup/world/data/input/verification, phased extraction order, and future-goal rules.
- Runtime code was not changed for G10.
Rollback notes:
- Revert documentation updates only.

## G11. Regression checklist

Status: [x]
Category: Verification infrastructure
Priority: P2
Depends on: G10
Scope:
- Create repeatable verification checklist for every future Codex pass.
Do:
- Include launch/smoke, syntax/parse, layout viewports, button clicks, modal z-order, popup drag/close, text wrapping, level-up, item machine, enemy/pickup loop.
- Point to available CLI probes/scripts.
Do not:
- Claim a check passed unless it was run.
- Replace goal-specific acceptance with one broad smoke.
Likely files:
- `Docs/ActiveTasks/GodotHtmlParityGoals.md`
- `Docs/Reports/GodotHtmlParityRegressionChecklist.md`
- `scripts/debug/layout_probe_cli.gd`
- `scripts/v2/prototype_smoke_cli.gd`
Acceptance criteria:
- Future goals can reuse the checklist.
- Each goal defines which subset must pass.
- Checklist records what to do if Godot cannot run.
Verification:
- Regression checklist created in `Docs/Reports/GodotHtmlParityRegressionChecklist.md`.
- File-level review confirmed the checklist includes launch/smoke, syntax/parse behavior, 960x540, 1152x648, wider desktop, button/input, modal z-order, popup drag/close, text wrapping, level-up/progression, item machine, enemy/pickup loop, and Godot-unavailable fallback.
- Dry-run executed with Godot 4.7:
  - G1 through G9 probe scenes all passed.
  - Scene smoke passed.
  - CLI smoke passed with `has_primary_module=true`, `first_purchase_paid=true`, `boss_package_two_pick_flow_exercised=true`, `all_popup_definitions_createable=true`, `all_items_apply_without_error=true`, `has_hud=true`, `has_popup_layer=true`, and `kill_count=4`.
Rollback notes:
- Revert checklist documentation/probe additions only.
