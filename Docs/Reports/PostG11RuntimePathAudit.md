# Post-G11 Runtime Path Audit

## Summary

G12 verified the actual Godot launch path after G0-G11. The active `project.godot` launch scene already pointed at the structured scene, but the old `res://scenes/main.tscn` still existed as a stale single-node `PrototypeGame` scene. That old scene has been converted into a delegate that instances `res://scenes/main/Main.tscn`, so opening either main scene now reaches the same structured layer architecture.

## 1. Active Main Scene Before Fix

- `project.godot` before the G12 fix already had:
  - `run/main_scene="res://scenes/main/Main.tscn"`
- The active project launch path was not masking G0-G11.
- However, `res://scenes/main.tscn` was stale:
  - It contained only `GameRoot` with `scripts/v2/prototype_game.gd`.
  - It did not explicitly instance `WorldLayer`, `EntityLayer`, `VfxLayer`, `HudLayer`, `PopupLayer`, `ModalLayer`, or `DebugLayer`.

## 2. Active Main Scene After Fix

- `project.godot` remains:
  - `run/main_scene="res://scenes/main/Main.tscn"`
- `res://scenes/main.tscn` now delegates to:
  - `res://scenes/main/Main.tscn`
- `project.godot` was not changed in G12 because it already pointed to the correct structured scene.

## 3. Whether `scenes/main/Main.tscn` Is Used

Yes.

- Direct project launch uses `res://scenes/main/Main.tscn`.
- G1-G9 debug probes preload or exercise `res://scenes/main/Main.tscn` directly where scene-level verification is needed.
- G12 runtime path probe verifies `project.godot` and both main scene paths.

## 4. Whether Old `scenes/main.tscn` Remains And Why

`res://scenes/main.tscn` remains as a compatibility/delegate scene.

Reason:

- Removing it could break editor bookmarks, older references, or external launch shortcuts.
- Leaving it as a stale direct `PrototypeGame` scene would create two competing main scenes.
- Delegating it to `res://scenes/main/Main.tscn` avoids stale behavior while keeping the path valid.

## 5. Layer Node Tree Result

Runtime tree verified for both `res://scenes/main/Main.tscn` and `res://scenes/main.tscn`:

```text
GameRoot
  WorldLayer   Node2D       script res://scripts/v2/prototype_world.gd
  EntityLayer  Node2D       no script; reserved structured layer
  VfxLayer     Node2D       no script; reserved structured layer
  HudLayer     CanvasLayer  layer 10  script res://scripts/v2/prototype_hud.gd
  PopupLayer   CanvasLayer  layer 20  script res://scripts/v2/prototype_popup_layer.gd
  ModalLayer   CanvasLayer  layer 50  script res://scripts/ui/modal/prototype_modal_layer.gd
  DebugLayer   CanvasLayer  layer 40  script res://scripts/debug/prototype_debug_layer.gd
```

CanvasLayer order:

- HUD below Popup: `10 < 20`
- Popup below Debug: `20 < 40`
- Debug below Modal: `40 < 50`
- Modal remains the top choice/game-over host.

## 6. Duplicate Layer Result

No duplicate major layers were found.

G12 runtime probe checked both active and legacy-delegate scenes and found exactly one instance of each:

- `WorldLayer`
- `EntityLayer`
- `VfxLayer`
- `HudLayer`
- `PopupLayer`
- `ModalLayer`
- `DebugLayer`

`PrototypeGame._setup_scene_nodes()` resolves existing scene nodes through `_resolve_or_create_child()` and binds:

- `world` to the existing `WorldLayer`
- `popup_layer` to the existing `PopupLayer`
- `modal_layer` to the existing `ModalLayer`
- `debug_layer` to the existing `DebugLayer`
- `hud` to the existing `HudLayer`

It did not create duplicate `HudLayer`, `PopupLayer`, or `ModalLayer` under `GameRoot`.

## 7. `HtmlLayoutMetrics` Runtime Use

`HtmlLayoutMetrics` is active in runtime behavior, not just present as a file.

Verified usage:

- HUD layout:
  - `scripts/v2/prototype_hud.gd` preloads `HtmlLayoutMetrics`.
  - It calls `HtmlLayoutMetrics.apply_desktop_hud_layout`.
  - It calls `HtmlLayoutMetrics.apply_choice_overlay_layout`.
  - It uses helper values for choice panel size, card width, card height, padding, text scale, debug visibility, and mobile controls.
- Choice/modal layout:
  - `PrototypeModalLayer` hosts `ModalRoot` at CanvasLayer `50`.
  - `PrototypeHud` builds the choice overlay under the modal parent and applies `HtmlLayoutMetrics.apply_choice_overlay_layout`.
  - The modal layer itself stays a host; the layout service is called by the HUD/choice renderer.
- Popup layout:
  - `scripts/v2/prototype_game.gd` routes popup sizes through `HtmlLayoutMetrics.popup_size_for_type`.
  - Popup placement HUD avoidance uses `HtmlLayoutMetrics` HUD rect helpers.
  - `scripts/v2/prototype_popup_layer.gd` calls `HtmlLayoutMetrics.popup_content_layout`.

Fixed offsets that remain:

- Scene-layer roots use full-rect anchors and CanvasLayer numbers; these are intentional structural setup values.
- HUD construction still creates placeholder controls before `_apply_html_layout()` applies service-driven runtime rects.
- Popup title buttons and small internal controls use local fixed sizes; these are widget dimensions, not page-level layout sources.
- No G12-blocking LayoutService activation gap was found.

## 8. Probe Results

G12 runtime path probe:

- Command:
  `C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe --headless --path . --log-file tmp\g12_runtime_path_probe.log --scene res://scenes/debug/G12RuntimePathProbe.tscn`
- Result: `g12_runtime_path_probe passed`

G1-G9 probes rerun:

- G1 input: passed
- G2 viewport: passed
- G3 layout service: passed
- G4 text wrapping: passed
- G5 HUD: passed
- G6 choice/modal: passed
- G7 popup: passed
- G8 progression: passed
- G9 core loop: passed

Smoke reruns:

- Scene smoke: passed
- CLI smoke: passed

CLI smoke result JSON:

- `has_primary_module=true`
- `first_purchase_paid=true`
- `boss_package_two_pick_flow_exercised=true`
- `all_popup_definitions_createable=true`
- `all_items_apply_without_error=true`
- `has_hud=true`
- `has_popup_layer=true`
- `kill_count=4`
- `popup_count=4`
- `enemy_count=6`

## 9. Remaining Risks

- `EntityLayer` and `VfxLayer` are present in the structured scene but currently have no scripts. This is acceptable for G12 because rendering is still owned by `PrototypeWorld`, but future extraction should decide whether these layers become active owners.
- Legacy scripts such as `scripts/game_root.gd`, `scripts/hud_layer.gd`, `scripts/popup_layer.gd`, `scripts/world_2d.gd`, and `scripts/data/game_data.gd` still exist. G10 documents them as inactive; they should not receive new behavior.
- `Docs/Reports/GodotVsHtmlAudit.md` still contains original mismatch descriptions from the initial audit. Some are now addressed by later goals, so the audit should be treated as historical unless a later cleanup goal refreshes it.
- The broad smoke scripts still instantiate `PrototypeGameScript` directly rather than the structured scene. The G12 probe covers the structured scene path, and G1-G9 scene probes cover structured scene behavior. A future verification cleanup could align smoke entrypoints if desired.

## 10. Recommended Next Goal

No G13 is required to complete G12.

Recommended optional next goal:

- G13. Legacy and audit freshness cleanup
- Scope: refresh stale audit descriptions, mark inactive legacy scripts more visibly, and decide whether broad smoke should instantiate `res://scenes/main/Main.tscn` instead of `PrototypeGameScript` directly.
- Do not implement this as part of G12.
