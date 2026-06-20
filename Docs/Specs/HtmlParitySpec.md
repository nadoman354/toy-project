# HTML Parity Spec

Purpose: `index.html`에서 추출한 Godot 적용용 기준 규칙이다. 이후 구현은 "비슷하게"가 아니라 아래 숫자와 동작을 기준으로 검증한다.

Reference source:
- HTML prototype: `index.html`
- Current Godot target: `project.godot` main scene `res://scenes/main/Main.tscn`
- Visual reference artifacts: `tmp/visual_compare/html_initial_metrics.json`, `tmp/visual_compare/html_popup_metrics.json`

## Viewport and Canvas

- `#app` and `#gameShell` fill the real browser viewport: `width: 100vw`, `height: 100vh`, `padding: 0`.
- `#gameShell` is `position: relative`, `overflow: hidden`, `background: #0b0f16`.
- `#fieldCanvas` is visually full viewport: `width: 100%`, `height: 100%`, `display: block`, `background: #101720`, `touch-action: none`.
- Runtime canvas size is not the initial HTML attribute size. `resizeCanvas()` sets:
  - `CONFIG.canvasWidth = max(320, floor(window.innerWidth || 960))`
  - `CONFIG.canvasHeight = max(320, floor(window.innerHeight || 540))`
  - `canvas.width = CONFIG.canvasWidth`
  - `canvas.height = CONFIG.canvasHeight`
- Camera follows player with viewport dimensions: `camera.x = player.x - canvasWidth / 2`, `camera.y = player.y - canvasHeight / 2`.
- Godot must use the actual visible viewport for world draw and UI roots. Do not preserve a global fixed 960x540 board, center board, or whole-root scale shortcut.

## World and Background

- Background always fills the viewport with `#101720`.
- HTML grid uses world-space step `40`; start/end are computed from camera and canvas bounds.
- Grid line style is `rgba(255, 255, 255, 0.045)` at width `1`.
- World-to-screen is `screen = world - camera`.
- Player is visually near the viewport center because camera is derived from player and current canvas size.
- Enemy and pickup visibility/spawn calculations use `CONFIG.canvasWidth` and `CONFIG.canvasHeight`, not fixed design dimensions.

## HUD Layout Constants

Desktop/reference rules:
- `difficultyHud`: top `10`, centered, width `min(340, viewport_width - 520)`, min width `240`, z-order above HUD background but below modal/popup, pointer-transparent.
- `cleanupComboHud`: top `64`, centered, width `min(260, viewport_width - 560)`, min width `190`, hidden unless combo is active, pointer-transparent.
- `combatHud`: top `12`, left `12`, width `270`.
- `economyHud`: top `12`, right `12`, width `255`.
- `statusPanel`: left `12`, bottom `12`, width `270`.
- `statusPanel.minimized`: width `132`, max height `42`, body hidden.
- `debugPanel`: right `12`, bottom `12`, width `250`, max height `viewport_height - 24`.
- `debugPanel.minimized`: width `132`, max height `42`, body hidden.
- `.panel`: padding `12`, border radius `8`, z-index `20`.
- HUD panels must not block popup/modal/world input outside their own interactive controls.

Mobile/coarse pointer rules:
- Active when `(pointer: coarse)` or viewport width `<= 860`.
- `debugPanel` is hidden.
- `difficultyHud`: top safe area or `5`, width `min(38vw, 210)`, min width `150`.
- `combatHud`: top safe area or `6`, left safe area or `6`, width `min(25vw, 156)`, max height `38vh`, scroll if needed.
- `economyHud`: top safe area or `6`, right safe area or `6`, width `min(26vw, 170)`, max height `38vh`, scroll if needed.
- `statusPanel`: left `max(96, safe_left + 90)`, bottom safe area or `8`, width `min(30vw, 194)`, max height `76`.
- At `max-width: 760`, `combatHud`, `economyHud`, and `statusPanel` may use width `210` before coarse-pointer overrides.

## Modal and Choice Overlay

- `itemOverlay`, `perkOverlay`, and `gameOverOverlay` cover the full viewport: `position: absolute`, `inset: 0`.
- Hidden overlays use `display: none` and must not block input.
- Visible overlays use flex centering: `display: flex`, `align-items: center`, `justify-content: center`.
- Overlay background is `rgba(4, 7, 12, 0.64)`.
- Overlay z-index is `5000`; it must appear above HUD, popup telegraphs, popups, debug, and mobile controls.
- Choice panel (`itemPanel`, `perkPanel`, `gameOverPanel`) rules:
  - width `min(680, viewport_width - 40)`
  - max height `viewport_height - 40`
  - padding `18`
  - overflow-y `auto`
  - touch-action `pan-y`
  - background `rgba(18, 24, 34, 0.98)`
  - border radius `10`
- Mobile/coarse choice panel:
  - width `min(560, viewport_width - 14)`
  - max height `viewport_height - 14`
  - padding `8`
- Initial module/perk selection uses the same overlay shape and must pause the game until a choice is made.

## Choice Cards

- Desktop choice grid: `grid-template-columns: repeat(3, 1fr)`, gap `12`, margin top `14`.
- At `max-width: 760`, choice grid uses one column.
- Mobile/coarse choice grid gap is `6`, margin top `7`.
- `.itemChoice` and `.perkChoice`:
  - desktop min height `150`
  - mobile/coarse min height `74`
  - left aligned
  - title `strong` font size `16`, margin bottom `8`
  - body `span` font size `13`, line-height `1.35`
- `.moduleChoice` and `.bossItemChoice`:
  - width `100%`
  - desktop min height `96`
  - padding `12`
  - title `strong` font size `15`, margin bottom `7`
  - body `span` font size `12`, line-height `1.35`
- `.bossPackageGrid`: two columns, gap `8`, margin top `10`.
- Item tag chips are inline, wrap as a row, and never break individual tag text: min height `18`, padding `2 6`, font size `10`, `white-space: nowrap`.

## Popup Size Table

Godot's `popup_size_for_type` must match this HTML `popupSizeFor(def)` table unless a later approved goal documents a deliberate difference.

| Popup type | Width | Height |
| --- | ---: | ---: |
| `terms` | 318 | 218 |
| `timed_reward` | 286 | 168 |
| `ad_buff` | 300 | 190 |
| `sponsored_ad` | 300 | 190 |
| `infection` | 286 | 168 |
| `infected_popup` | 292 | 150 |
| `first_purchase_package` | 336 | 236 |
| `interest_offer` | 350 | 250 |
| `recurring_investment` | 342 | 230 |
| `loan_offer` | 342 | 230 |
| `stock_market` | 342 | 230 |
| `stock_broker_app` | 300 | 260 |
| `clean_challenge` | 320 | 190 |
| `volatile_popup` | 310 | 178 |
| `popup_store` | 326 | 230 |
| `boss_package_ad` | 440 | 430 |
| `system_notice` | 260 | 120 |
| `security_installer` | 330 | 220 |
| `security_update_notice` | 292 | 150 |
| default | 252 | 132 |

## Popup Z-Order, Drag, Close, and Minimize

- `popupLayer`: full viewport, z-index `1000`, `pointer-events: none`.
- `popupTelegraphLayer`: full viewport, z-index `900`, `pointer-events: none`.
- Individual `.popupWindow`: `position: absolute`, `pointer-events: auto`, min width `220`, max width `min(460, viewport_width - 24)`.
- Popup title bar:
  - min height `30`
  - padding `6 8`
  - cursor `grab`, active cursor `grabbing`
  - `touch-action: none`
  - starts drag only from title bar
  - ignores drag when event target is `button`, `input`, `select`, `textarea`, or `a`
- Drag behavior:
  - pointerdown stores pointer id and origin
  - pointer capture is used if available
  - document-level pointermove updates popup position
  - document-level pointerup/pointercancel ends drag even if pointer is outside the title bar
  - drag multiplier is `max(0.5, 1 + popupDragSpeedMultiplier)`
  - popup position clamps to popup layer with margin `4`
  - release settles popup by pushing it out of excessive popup overlap
- Click anywhere on a popup brings it forward by incrementing z-index.
- Popup close button is `24x22`, text `x`, and stops propagation on pointerdown/click.
- `stock_broker_app` has a minimize button instead of a close button and cannot be normally closed.
- `first_purchase_package` has no normal close button and cannot be closed except through its explicit pay/reject flow.
- Locked financial popups must resolve through their internal controls where HTML requires it.
- Popup input grace:
  - `.popupWindow.inputGrace .popupBody button` has pointer-events disabled, grayscale, and opacity `0.48`.
  - input grace badge text is `입력 유예 중`.

## Button and Input Propagation

- Hidden overlays must not block input.
- Visible modal overlay blocks world input but must not block its own buttons.
- Popup layer roots must be pointer-transparent; only real popup windows and buttons receive input.
- Choice card buttons must remain the clickable owner. Any child labels/containers inside a Button must ignore mouse input in Godot.
- Close/minimize buttons must stop propagation so a close click does not start drag.
- Disabled state reference:
  - `rollItemButton.disabled = gameOver || paused || selectingItem || selectingPerk || selectingModule || gold < currentItemRollCost()`
  - `openInventoryButton.disabled = gameOver || selectingItem || selectingPerk || selectingModule || selectingPaidReward`
  - popup purchase buttons update disabled state from current gold/state each UI refresh.
- Mobile fallback click reference:
  - floating joystick does not start from `.panel`, `.popupWindow`, `button`, `input`, `select`, `textarea`, `a`, `label`, overlays, or mobile buttons.
  - while joystick is active, touchstart/touchmove/touchend tracks button tap candidates.
  - moved threshold is `12` pixels.
  - valid fallback tap calls `button.click()` and suppresses the following native click for `500ms`.

## Text Wrapping

- Default HUD labels are single-line unless explicitly body text.
- Popup titles use ellipsis: flex child with `min-width: 0`, overflow hidden, text-overflow ellipsis, white-space nowrap.
- Choice titles are single-line in cards; long title text trims/ellipsizes instead of wrapping one character per line.
- Choice body/description text wraps only inside stable-width cards.
- Item tags do not wrap within the chip; the chip row wraps between chips.
- Popup body text wraps at stable popup body width; `system_notice` body preserves line breaks.
- Button text may wrap where the HTML button is multi-line, but button dimensions must be stable and large enough for the expected Korean text.

## Level-Up and Progression

- Initial run starts paused and immediately opens primary attack module selection.
- Primary module selection sets `primaryModule`, ensures `primaryMastery >= 1`, updates recent perk text, closes module overlay, and unpauses.
- `checkLevelUp()` stops when any selection/modal is active.
- On each level-up:
  - subtract current `xpNeed`
  - increment `level`
  - set `xpNeed = round(xpNeed * CONFIG.xpRequirementGrowth)`
  - call `handleLevelChoice()`
  - if no special choice opens, apply automatic mastery level-up
- `handleLevelChoice()` reference gates:
  - if `level >= 5` and no `secondaryModule`, open secondary module selection
  - if `level >= 9` and no primary form upgrade, open primary attack form selection
  - if `level >= 13` and no primary mechanic upgrade, open primary mechanic selection
  - if `level >= 17` and no primary scaling upgrade, open build scaling selection
  - otherwise no choice overlay; apply mastery level-up
- Synergy/deepening functions exist in HTML, but the default `handleLevelChoice()` path above does not open them by default.

## Item Machine and Item Choices

- Item machine cost starts at `25`.
- Cost formula: `itemRollCost * itemRollCostGrowth ^ itemRollCount`, then discounts, optional cap, and active item/security multipliers.
- `rollItem()` returns without action if `gameOver`, `paused`, selecting, or gold is below cost.
- On successful roll:
  - subtract cost
  - decrement next-item discount uses and remove exhausted discounts
  - open item selection overlay
  - pause run while selecting
- Item choice overlay title: `아이템 선택`.
- Item choice overlay description: `골드를 지불했습니다. 패시브 아이템 1개를 선택해 현재 런 성능을 누적 성장시키세요.`
- Item choices are chosen from weighted item pool without duplicates in the shown set.
- HTML base rarity weights: `Common 50`, `Rare 27`, `Epic 12`, `Cursed 8`, unless an item has explicit `weight`.
- Applying an item applies its effects, increments `itemCounts[item.id]`, updates recent item HUD, closes overlay, and resumes.

## Gold, XP, and Pickup Loop

- Normal enemy kill drops:
  - gold pickup value `CONFIG.goldPerKill` (`5`)
  - XP pickup value `CONFIG.xpPerKill` (`10`)
  - magnet drop chance `0.025`
  - heal drop chance `0.025`
- Pickup range starts at `CONFIG.pickupRange` (`48`) and includes item/stat modifiers.
- HTML pickup behavior pulls pickups toward the player when within pickup range; collection occurs when distance is less than `player.radius + pickup.radius + 8`.
- Magnet pickup forces gold/XP pickups to move toward player.
- Collecting gold uses `addGold`.
- Collecting XP uses `addXp`, then `checkLevelUp`.
- Pickups are filtered out after collection.

## Enemy, Boss, and Combat

- Normal enemy spawn:
  - base HP `24`
  - base speed `82`
  - damage `18`
  - radius `12`
  - spawn interval `1.65`, min `0.45`
  - default spawn is at a viewport edge with margin `80`
  - wave side spawn uses margin `86`
  - ring spawn radius is `max(canvasWidth, canvasHeight) * random(0.58, 0.76)`
- Enemy chase:
  - move toward player each tick by normalized vector * speed * dt
  - contact cooldown is `0.85`
  - contact damage subtracts enemy damage and sets player hit flash `0.16`
- Boss spawn:
  - times `[75, 150]`
  - spawn margin `140`
  - radius `28 + tier * 3`
  - speed at least `38`, otherwise based on enemy speed and tier
  - rewards: base gold `80`, base XP `80`, plus tier increments
  - boss death creates boss package popup
- Boss HP estimate uses level, tier, difficulty, enemy time scale, and estimated player DPS:
  - `CONFIG.bossBaseHP * tierMultiplier * enemyTimeScale() * stageMultiplier + estimatedPlayerDps() * targetSurvival`
  - `tierMultiplier = 1 + (tier - 1) * 0.85 + level * 0.04`
  - target survival is `13`, `20`, or `28` seconds for tier 1, 2, or later.
- Auto attack starts only after module selection. It targets nearest enemies in range and uses selected module/form/mechanic/scaling rules.

## Boss Package Flow

- Boss death opens `boss_package_ad`.
- Boss package popup size is `440x430`.
- Boss package cost:
  - tier 1: `80`
  - tier 2: `140`
  - tier 3+: `220 + (tier - 3) * 90`
- Purchase opens paid reward choice.
- Candidate item count is `6`.
- Player selects exactly `2` items.
- Completing selection applies both item rewards, increments boss package metrics, closes overlay, and resumes.

## Debug and Verification Notes

- Existing Godot verification scripts:
  - `scripts/v2/prototype_smoke_cli.gd`
  - `scripts/debug/layout_probe_cli.gd`
  - `scripts/debug/visual_compare_godot_cli.gd`
- `layout_probe_cli.gd` verifies current `HtmlLayoutMetrics` contracts. It can pass even when `HtmlLayoutMetrics` itself differs from this spec; future parity goals must compare against this document too.
- Required manual/visual viewports for future layout checks:
  - `960x540`
  - `1152x648`
  - wider desktop such as `1920x1080`
  - compact/mobile landscape and portrait when a goal touches responsive UI.
- For click goals, verification must exercise actual buttons, not just node existence:
  - item machine
  - inventory
  - choice cards
  - popup close/minimize
  - popup content action buttons
  - debug buttons
  - hidden overlay pass-through
