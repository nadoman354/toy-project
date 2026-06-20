# Godot vs HTML Audit

Purpose: 현재 Godot 워크트리를 HTML prototype 기준과 비교한 G0 감사 보고서다. 이 보고서는 구현 지시가 아니라 이후 Goals의 근거다.

Inspection date: 2026-06-20

## 1. Gameplay / Design Behavior

### M1. 레벨업 진행 타이밍이 HTML과 다르다

- HTML/reference behavior: `handleLevelChoice()`는 보조 모듈 `level >= 5`, 1차 공격 방식 `level >= 9`, 1차 기믹 `level >= 13`, 1차 스케일링 `level >= 17` 순서다. 특수 선택이 없으면 선택창을 열지 않고 `applyMasteryLevelUp()`으로 숙련도를 자동 상승시킨다.
- Current Godot behavior: `open_level_choice()`는 `level == 3`에 보조 모듈을 열고, `next_growth_choice_label()`은 공격 방식 `[5, 9]`, 공격 기믹 `[7, 13]`을 열 수 있다. 특수 선택이 없으면 `성장 보상` perk 선택창을 연다.
- Why it matters: 진행 템포, 선택 빈도, 초반 전투 난이도, HTML 원본의 빌드 흐름이 달라진다.
- Suspected files: `scripts/v2/prototype_game.gd`, `scripts/data/prototype_data.json`
- Suggested fix direction: G8에서 HTML `handleLevelChoice()`를 기준으로 Godot progression gate를 맞추거나, 승인된 차이만 config flag로 명시한다. 데이터는 삭제하지 말고 게이트만 조정한다.
- Verification method: primary 선택 후 XP를 강제로 지급해 Lv.5/Lv.9/Lv.13/Lv.17에서 열리는 선택 종류를 기록한다. Lv.2-4에서는 보조 모듈이 열리지 않아야 한다.

### M2. 기본 레벨업 보상이 선택형 perk로 바뀌었다

- HTML/reference behavior: 특수 progression gate가 없으면 `applyMasteryLevelUp()`이 자동으로 primary/secondary mastery를 올리고 system popup을 만든다.
- Current Godot behavior: `open_level_choice()`의 기본 경로는 `open_item_like_overlay("성장 보상", ...)`로 3개 perk 선택을 요구한다.
- Why it matters: 플레이어 선택 수, 정지 시간, perk 획득량이 HTML 기준보다 커진다.
- Suspected files: `scripts/v2/prototype_game.gd`
- Suggested fix direction: G8에서 기본 경로를 자동 mastery로 맞추고, 별도 perk 선택이 필요한 경우 승인된 feature flag로 숨긴다.
- Verification method: 특수 gate가 아닌 레벨업에서 modal이 열리지 않고 mastery와 recent text/system popup만 갱신되는지 확인한다.

### M3. 보스 HP 공식이 HTML 기준과 다르다

- HTML/reference behavior: boss HP는 `bossBaseHP * tierMultiplier * enemyTimeScale() * stageMultiplier + estimatedPlayerDps() * targetSurvival`이며 `tierMultiplier = 1 + (tier - 1) * 0.85 + level * 0.04`이다.
- Current Godot behavior: `boss_hp_estimate()`는 `bossBaseHP * (1 + 0.55 * (tier - 1)) * difficulty_combat_pressure().enemyHpMultiplier` 형태로 DPS, level, target survival을 반영하지 않는다.
- Why it matters: 보스 체력 스케일과 처치 시간이 HTML과 달라져 보스 패키지/보상 흐름 검증도 흔들린다.
- Suspected files: `scripts/v2/prototype_game.gd`
- Suggested fix direction: G9 또는 별도 combat parity에서 HTML 공식을 이식하고 기존 값 차이는 문서화한다.
- Verification method: 동일 level/tier/difficulty에서 HTML 공식 산출값과 Godot `boss_hp_estimate()`를 비교한다.

### M4. pickup 흡입/수집 루프가 HTML과 다르다

- HTML/reference behavior: pickup은 범위 안에서 player 쪽으로 이동하고, 실제 수집은 `player.radius + pickup.radius + 8` 안에 들어왔을 때 발생한다.
- Current Godot behavior: `update_pickups()`는 일반 pickup을 `effective_pickup_range()` 이내에서 즉시 수집한다. magnet pickup은 다른 pickup을 player로 이동시키지만 기본 gold/xp 흡입 단계가 없다.
- Why it matters: 획득 감각, pickup range 아이템 가치, 이동 동선이 달라진다.
- Suspected files: `scripts/v2/prototype_game.gd`, `scripts/v2/prototype_world.gd`
- Suggested fix direction: G9에서 HTML처럼 attraction phase와 collection radius를 분리한다.
- Verification method: pickup을 pickup range 가장자리에 배치하고 한 프레임 후 즉시 수집되지 않고 이동하는지 확인한다.

### M5. normal enemy spawn 위치 공식이 HTML과 다르다

- HTML/reference behavior: 기본 spawn은 camera viewport edge 기준 margin `80`, side wave margin `86`, ring wave는 `max(canvasWidth, canvasHeight) * random(0.58, 0.76)`이다.
- Current Godot behavior: `spawn_position_for_wave()`는 player 기준으로 `max(viewport.x, viewport.y) * 0.62 + 80` 거리의 ring/side/edge 후보를 만든다.
- Why it matters: 적 접근 방향과 첫 접촉 시간이 달라진다.
- Suspected files: `scripts/v2/prototype_game.gd`
- Suggested fix direction: G9에서 HTML edge/camera 기준 spawn으로 맞춘다.
- Verification method: fixed camera/player/viewport에서 spawn 위치가 viewport edge margin 규칙을 만족하는지 샘플링한다.

## 2. Visual / UI / Layout

### M6. choice panel desktop width가 HTML보다 넓어진다

- HTML/reference behavior: desktop choice panel width는 항상 `min(680, viewport_width - 40)`이다.
- Current Godot behavior: `HtmlLayoutMetrics.choice_panel_size()`는 viewport width `>= 1600`에서 base width `900`, height `450`을 사용한다.
- Why it matters: 1920x1080에서 선택 카드 비율과 텍스트 줄 수가 HTML reference와 달라진다.
- Suspected files: `scripts/ui/html_layout_metrics.gd`, `scripts/v2/prototype_hud.gd`
- Suggested fix direction: G6 또는 G3에서 HTML 기준 `680x365` 계열로 되돌리고, 큰 화면 확장은 승인된 차이로 따로 문서화하지 않는 한 제거한다.
- Verification method: 1920x1080에서 choice panel rect가 `x=620`, `w=680`에 가까워야 한다.

### M7. choice card min height가 HTML보다 작다

- HTML/reference behavior: `.itemChoice`/`.perkChoice` desktop min height `150`, mobile/coarse min height `74`; `.moduleChoice` min height `96`.
- Current Godot behavior: `choice_card_min_height("item")`은 desktop `132`, `module`은 `120`, `contract`은 `106`, `inventory`는 `112`; `ChoiceCard.tscn` 기본 min size는 `204x112`.
- Why it matters: 아이템 설명, 현재/선택 후 효과, 태그 줄이 HTML과 다른 밀도로 표시되고 clipping 위험이 있다.
- Suspected files: `scripts/ui/html_layout_metrics.gd`, `scenes/ui/cards/ChoiceCard.tscn`, `scripts/v2/prototype_hud.gd`
- Suggested fix direction: G6/G4에서 카드 종류별 HTML 최소 높이와 내용 요구 높이를 분리한다.
- Verification method: item/perk/module 선택 화면에서 카드 rect, scroll height, clipping 여부를 960x540과 1152x648에서 비교한다.

### M8. popup size table이 HTML과 다르다

- HTML/reference behavior: `popupSizeFor()` table은 예를 들어 `terms 318x218`, `first_purchase_package 336x236`, `boss_package_ad 440x430`, `popup_store 326x230`이다.
- Current Godot behavior: `HtmlLayoutMetrics.popup_size_for_type()`는 `terms 302x270`, `first_purchase_package 318x202`, `boss_package_ad 420x390`, `popup_store 306x204` 등 다수 값이 다르다.
- Why it matters: popup cluster 시각 밀도, 버튼 위치, overlap 회피, HTML screenshot parity가 달라진다.
- Suspected files: `scripts/ui/html_layout_metrics.gd`, `scripts/v2/prototype_popup_layer.gd`
- Suggested fix direction: G7에서 size table을 spec table과 맞추고 내용 레이아웃이 overflow 없이 버티는지 함께 검증한다.
- Verification method: 각 popup type 생성 후 panel size가 `Docs/Specs/HtmlParitySpec.md` table과 일치하는지 probe한다.

### M9. world grid 간격이 HTML과 다르다

- HTML/reference behavior: background grid step은 `40`.
- Current Godot behavior: `PrototypeWorld._draw_background()` grid step은 `48`.
- Why it matters: 월드 스케일 감각과 HTML 시각 기준이 달라진다.
- Suspected files: `scripts/v2/prototype_world.gd`
- Suggested fix direction: G2/G9에서 grid step과 line alpha를 HTML 기준으로 맞춘다.
- Verification method: 960x540 screenshot에서 grid line 간격이 40px 기준인지 확인한다.

## 3. Structure / Architecture

### M10. runtime ownership이 여전히 `prototype_game.gd`에 집중되어 있다

- HTML/reference behavior: 원본은 단일 HTML prototype이므로 구조 기준은 없지만, 이번 목표는 유지 가능한 Godot 구조로 점진 이전하는 것이다.
- Current Godot behavior: `scripts/v2/prototype_game.gd`가 state, progression, combat, enemy, pickup, popup, economy, item, debug action 대부분을 소유한다. 일부 `RunCoordinator`, `PopupClosePolicy`, `HtmlLayoutMetrics`, layer scenes가 생겼지만 domain logic은 아직 monolith다.
- Why it matters: 작은 목표 구현 중 회귀 범위가 커지고, 입력/레이아웃/전투 수정이 같은 파일에서 충돌한다.
- Suspected files: `scripts/v2/prototype_game.gd`, `scripts/systems/run_coordinator.gd`, `scripts/systems/popup_close_policy.gd`, `scripts/ui/html_layout_metrics.gd`
- Suggested fix direction: `Docs/Specs/GodotArchitectureOwnership.md`의 owner 표와 단계별 추출 순서를 따른다. 즉시 full rewrite는 금지하고, 새 코드만 명확한 owner로 추가한다.
- Verification method: ownership 문서에 각 시스템 owner와 추출 순서가 있고, 이후 goal diff가 unrelated domain을 건드리지 않는지 확인한다.

### M11. legacy prototype scripts가 남아 있다

- HTML/reference behavior: 단일 기준은 `index.html`.
- Current Godot behavior: active main scene은 `scripts/v2/prototype_game.gd`를 쓰지만 `scripts/game_root.gd`, `scripts/hud_layer.gd`, `scripts/popup_layer.gd`, `scripts/world_2d.gd`, `scripts/data/game_data.gd`가 남아 있다.
- Suggested fix direction: `Docs/Specs/GodotArchitectureOwnership.md`의 active vs legacy 구분을 따른다. legacy 파일 삭제는 별도 cleanup goal에서만 수행한다.
- Why it matters: 이후 Codex pass가 활성 파일과 legacy 파일을 혼동할 수 있다.
- Suspected files: top-level `scripts/*.gd`, `scripts/v2/*.gd`, `scenes/main.tscn`, `scenes/main/Main.tscn`
- Suggested fix direction: G10에서 legacy/active 파일 구분을 명시한다. 이번 phase에서는 삭제하지 않는다.
- Verification method: ActiveTask에 "Likely files"를 명시하고, project main scene dependency를 기준으로 활성 경로를 확인한다.

### M12. layout probe가 Godot helper 자체를 기준으로 검증한다

- HTML/reference behavior: 기준은 HTML CSS/JS 숫자다.
- Current Godot behavior: `scripts/debug/layout_probe_cli.gd`는 `HtmlLayoutMetrics` 값을 expected로 사용한다. helper가 HTML과 달라도 probe가 통과할 수 있다.
- Why it matters: 잘못된 Godot metric이 검증의 기준이 되는 self-fulfilling test가 된다.
- Suspected files: `scripts/debug/layout_probe_cli.gd`, `scripts/ui/html_layout_metrics.gd`
- Suggested fix direction: G3/G11에서 spec constants와 helper constants를 비교하는 테스트를 추가한다.
- Verification method: popup size table, choice width, HUD constants를 spec literal과 비교하는 검증을 추가한다.

## 4. Input / Interaction

### M13. popup click-to-front가 HTML보다 제한적이다

- HTML/reference behavior: popup element 전체의 `mousedown`이 `bringPopupToFront(popup)`를 호출한다.
- Current Godot behavior: `PrototypePopupLayer._drag_event()`에서 title bar pointer down 시 `bring_popup_to_front()`가 호출된다. content/body/control 클릭이 bring-to-front를 보장하는지는 확인되지 않았다.
- Why it matters: 겹친 popup에서 뒤쪽 popup 내용 버튼을 누르기 전 z-order가 HTML과 다를 수 있다.
- Suspected files: `scripts/v2/prototype_popup_layer.gd`
- Suggested fix direction: G7에서 panel/container click 또는 gui_input으로 전체 popup click-to-front를 구현하되 버튼 동작을 방해하지 않도록 한다.
- Verification method: 겹친 popup 두 개를 만든 뒤 뒤 popup body/control 영역 클릭이 z를 올리는지 확인한다.

### M14. popup drag release가 title bar 밖에서 끝나지 않을 위험이 있다

- HTML/reference behavior: `document`의 pointerup/pointercancel이 drag를 끝내므로 release anywhere가 동작한다.
- Current Godot behavior: drag release 처리는 title bar `gui_input`의 mouse button release 경로에 있다. title bar 밖에서 release될 때 `settle_dragged_popup()`이 항상 호출되는지 불확실하다.
- Why it matters: drag state가 stuck되면 popup input과 world input이 깨진다.
- Suspected files: `scripts/v2/prototype_popup_layer.gd`, `scripts/v2/prototype_game.gd`
- Suggested fix direction: G7에서 document-level에 해당하는 `_input`/root gui release 처리를 추가하고 `state.draggingPopup` 정리를 보장한다.
- Verification method: title bar에서 drag 시작 후 popup 밖에서 release하고, 다음 frame에 `draggingPopup == null`인지 확인한다.

### M15. 모바일 fallback click 로직이 HTML만큼 구현되어 있지 않다

- HTML/reference behavior: joystick active 중에도 touch candidate를 추적하고, 12px 이하 이동이면 `button.click()`을 호출한 뒤 500ms native click을 suppress한다.
- Current Godot behavior: `InputController`와 `PrototypeHud._unhandled_input()`는 floating joystick movement를 처리하지만 HTML의 fallback button tap 복구와 동일한 로직은 보이지 않는다.
- Why it matters: 모바일에서 조이스틱/버튼 동시 조작 시 버튼 클릭 누락이 생길 수 있다.
- Suspected files: `scripts/v2/input_controller.gd`, `scripts/v2/prototype_hud.gd`
- Suggested fix direction: G1에서 모바일 fallback click 필요 여부를 재현하고 구현하거나, Godot event model에서 불필요함을 검증으로 증명한다.
- Verification method: 모바일 viewport에서 joystick active 상태로 item/debug/popup button tap을 시뮬레이션하거나 수동 검증한다.

### M16. hidden/visible overlay input 정책은 일부 맞지만 전면 검증이 없다

- HTML/reference behavior: hidden overlays는 `display: none`; visible modal은 world input을 막고 자기 버튼은 동작한다.
- Current Godot behavior: `show_choices()`는 `choiceOverlay.mouse_filter = STOP`, `hide_choices()`는 `IGNORE`; scene default는 `IGNORE`. Game over overlay도 visible일 때 STOP이다.
- Why it matters: 현재 구현은 방향이 맞지만 G1 acceptance의 모든 버튼을 실제 클릭 검증해야 한다.
- Suspected files: `scripts/v2/prototype_hud.gd`, `scenes/ui/modal/ChoiceOverlay.tscn`, `scripts/ui/modal/prototype_modal_layer.gd`
- Suggested fix direction: G1에서 hovered control diagnostic과 실제 click checklist를 수행한다.
- Verification method: item machine, inventory, choice cards, popup close/content buttons, debug buttons, hidden overlay pass-through를 모두 확인한다.

## 5. Data / Progression

### M17. active JSON과 legacy `GameData.gd`가 중복된다

- HTML/reference behavior: 기준 데이터는 HTML constants/tables다.
- Current Godot behavior: active v2 path는 `scripts/data/prototype_data.json`을 `DataRegistry`로 읽지만, `scripts/data/game_data.gd`에도 별도 constants/items/popups가 있다.
- Why it matters: future pass가 잘못된 데이터 파일을 수정할 수 있다.
- Suspected files: `scripts/data/prototype_data.json`, `scripts/data/data_registry.gd`, `scripts/data/game_data.gd`
- Suggested fix direction: G10에서 active data owner를 `prototype_data.json`으로 명시한다. 이번 phase에서 Resource 변환/삭제 금지.
- Verification method: runtime이 `DATA_PATH = res://scripts/data/prototype_data.json`을 사용함을 확인한다.

### M18. item rarity weights가 HTML과 다르다

- HTML/reference behavior: weighted item rarity defaults are `Common 50`, `Rare 27`, `Epic 12`, `Cursed 8`.
- Current Godot behavior: `weighted_item_index()` uses `Common 44`, `Rare 28`, `Epic 12`, `Cursed 7`.
- Why it matters: item economy/progression distribution differs.
- Suspected files: `scripts/v2/prototype_game.gd`
- Suggested fix direction: G9 or G8에서 HTML weights로 맞추거나 approved balance difference로 문서화한다.
- Verification method: code-level literal check and seeded roll distribution smoke.

### M19. progression config flags는 있으나 HTML default gate와 결합 방식이 다르다

- HTML/reference behavior: default `handleLevelChoice()` only gates secondary/form/mechanic/scaling by level and missing upgrade.
- Current Godot behavior: `CONFIG`에는 flags가 있고 `PROGRESSION_CHOICE_DEFAULTS`도 있지만 Godot level arrays and default perk overlay가 HTML default와 다르다.
- Why it matters: advanced choices를 숨겼더라도 기본 progression mismatch가 남는다.
- Suspected files: `scripts/v2/prototype_game.gd`, `scripts/data/prototype_data.json`
- Suggested fix direction: G8에서 flags는 유지하되 HTML default path를 우선한다.
- Verification method: config flag true/false matrix에서 default path가 HTML과 일치하는지 확인한다.

## 6. Risk / Blockers

### M20. 현재 워크트리에 기존 변경사항과 미추적 구조화 파일이 있다

- HTML/reference behavior: 해당 없음.
- Current Godot behavior: `git status --short` 기준 `project.godot`, `scripts/data/prototype_data.json`, `scripts/v2/*` 등이 수정되어 있고 `resources/`, `scenes/layers/`, `scripts/systems/`, `scripts/ui/` 등이 미추적이다.
- Why it matters: G0 이후 구현 pass가 사용자/기존 작업을 덮어쓸 위험이 있다.
- Suspected files: repository-wide
- Suggested fix direction: 모든 goal은 diff 범위를 좁히고 기존 변경을 되돌리지 않는다.
- Verification method: 각 pass 시작/종료 시 `git status --short` 확인.

### M21. Godot 실행 가능 여부가 아직 G0에서 runtime 검증되지 않았다

- HTML/reference behavior: 브라우저 prototype은 `index.html` 실행 기준이다.
- Current Godot behavior: smoke/log artifacts and CLI scripts are present, but G0은 문서 setup/audit 작업이므로 runtime gameplay verification을 수행하지 않았다.
- Why it matters: 목표 완료 조건을 runtime success로 과장하면 안 된다.
- Suspected files: `scripts/v2/prototype_smoke_cli.gd`, `scripts/debug/layout_probe_cli.gd`
- Suggested fix direction: G1 이후 각 goal에서 필요한 subset을 실제 실행한다. Godot 실행이 안 되면 file-level verification만 명시하고 status를 `[~]`로 둔다.
- Verification method: goal별 acceptance에 맞춰 CLI smoke, layout probe, screenshot/manual click 중 하나 이상을 선택한다.

### M22. `HtmlLayoutMetrics`가 이미 존재하지만 G3를 완료로 볼 수 없다

- HTML/reference behavior: layout helper는 HTML/CSS 규칙을 번역해야 한다.
- Current Godot behavior: helper file은 존재하고 HUD/choice/popup 일부가 사용하지만, choice width and popup table이 HTML spec과 다르다.
- Why it matters: "파일 존재"와 "HTML parity service 완료"는 다르다.
- Suspected files: `scripts/ui/html_layout_metrics.gd`, `scripts/v2/prototype_hud.gd`, `scripts/v2/prototype_popup_layer.gd`
- Suggested fix direction: G3는 dedicated goal로 남긴다. 단순 숫자 수정만으로 완료 처리하지 않는다.
- Verification method: helper의 public functions가 spec constants를 반환하고 HUD/modal/popup이 scattered magic offsets 대신 helper를 사용하는지 확인한다.
