extends RefCounted
class_name GameData

const CONFIG = {
	"canvas_width": 960,
	"canvas_height": 540,
	"player_max_hp": 100.0,
	"player_move_speed": 180.0,
	"player_damage": 10.0,
	"player_attack_interval": 0.6,
	"player_attack_range": 140.0,
	"pickup_range": 48.0,
	"ranged_projectile_speed": 420.0,
	"enemy_hp": 24.0,
	"enemy_speed": 82.0,
	"enemy_damage": 18.0,
	"enemy_spawn_interval": 1.65,
	"enemy_spawn_interval_min": 0.45,
	"gold_per_kill": 5,
	"xp_per_kill": 10,
	"item_roll_cost": 25,
	"item_roll_cost_growth": 1.18,
	"xp_base_requirement": 40,
	"xp_requirement_growth": 1.25,
	"popup_base_spawn_interval": 11.5,
	"popup_min_spawn_interval": 4.2,
	"popup_pressure_ramp_seconds": 145.0,
	"max_open_popups": 5,
	"emergency_close_cooldown": 9.0,
	"boss_spawn_times": [75.0, 150.0],
	"boss_base_hp": 504.0,
	"boss_gold_reward": 80,
	"boss_xp_reward": 80,
}

static func items() -> Array:
	return [
		_item("damage_up", "공격력 증가", "피해량 +35%", "Common", ["combat", "damage"], {"stat": "damage_multiplier", "value": 0.35}),
		_item("attack_speed_up", "공격 속도 증가", "공격 간격 -10%", "Common", ["combat", "tempo"], {"stat": "attack_interval_multiplier", "value": -0.1}),
		_item("range_up", "사거리 증가", "공격 사거리 +15%", "Common", ["combat", "range"], {"stat": "attack_range_multiplier", "value": 0.15}),
		_item("move_speed_up", "이동 속도 증가", "이동 속도 +10%", "Common", ["mobility"], {"stat": "move_speed_multiplier", "value": 0.1}),
		_item("max_hp_up", "최대 HP 증가", "최대 HP +20", "Common", ["health"], {"stat": "max_hp", "value": 20}),
		_item("magnetic_cursor", "자석 커서", "골드/XP 획득 범위 +30%", "Common", ["pickup"], {"stat": "pickup_range_multiplier", "value": 0.3}),
		_item("sharp_copy", "예리한 문구", "치명타 확률 +10%", "Common", ["crit"], {"stat": "crit_chance", "value": 0.1}),
		_item("piercing_ad_shot", "관통 탄환", "투사체 관통 +1", "Rare", ["projectile"], {"stat": "extra_targets", "value": 1}),
		_item("clean_desk", "정리된 책상", "열린 팝업이 2개 이하일 때 피해량 +40%", "Rare", ["clean"], {"stat": "clean_desk_damage_multiplier", "value": 0.4}),
		_item("clutter_adaptation", "난장판 적응", "열린 팝업 1개당 공격 간격 -4%, 최대 -20%", "Rare", ["clutter"], {"stat": "clutter_attack_interval_per_popup", "value": -0.04}),
		_item("gold_bullets", "골드 탄환", "보유 골드 50G당 피해량 +8%, 최대 +120%", "Rare", ["gold", "damage"], {"stat": "gold_bullet_damage_multiplier", "value": 0.08}),
		_item("data_collector", "데이터 수집기", "골드/XP 획득 범위 +45%, 팝업 생성률 +5%", "Rare", ["pickup", "popup"], {"effects": [{"stat": "pickup_range_multiplier", "value": 0.45}, {"stat": "popup_spawn_rate_multiplier", "value": 0.05}]}),
		_item("inflated_damage_number", "과장된 피해 수치", "치명타 피해 +50%", "Rare", ["crit"], {"stat": "crit_damage_multiplier", "value": 0.5}),
		_item("clickbait_headline", "클릭베이트 헤드라인", "치명타 확률 +6%, 치명타 피해 +25%", "Rare", ["crit"], {"effects": [{"stat": "crit_chance", "value": 0.06}, {"stat": "crit_damage_multiplier", "value": 0.25}]}),
		_item("emergency_training", "긴급 대처 훈련", "Space 긴급 닫기 후 5초간 이동속도 +30%", "Rare", ["emergency"], {"stat": "emergency_move_speed_multiplier", "value": 0.3}),
		_item("auto_click_macro", "자동 정리 매크로", "8초마다 방해 팝업을 자동 정리하고 정리 콤보를 유지합니다.", "Epic", ["automation"], {"stat": "auto_close_basic_interval", "value": 8}),
		_item("sponsored_blade", "스폰서드 블레이드", "스폰서 광고가 열려 있으면 투사체 공격이 추가 발사됩니다.", "Epic", ["sponsored"], {"stat": "sponsored_double_hit", "value": 1}),
		_item("overheated_lootbox", "과열된 랜덤박스", "아이템 선택 후 10초간 피해량 +15%", "Epic", ["burst"], {"stat": "purchase_damage_burst", "value": 0.15}),
		_item("premium_cursor", "프리미엄 커서", "팝업 드래그 중 공격 간격 -20%", "Epic", ["popup", "tempo"], {"stat": "drag_attack_interval_multiplier", "value": -0.2}),
		_item("window_breaker", "창문 파쇄기", "팝업을 닫으면 플레이어 주변 적에게 15 피해", "Epic", ["popup", "damage"], {"stat": "popup_close_damage", "value": 15}),
		_item("malicious_optimization", "악성 최적화", "피해량 +100%, 팝업 생성률 +30%", "Cursed", ["curse", "damage"], {"effects": [{"stat": "damage_multiplier", "value": 1.0}, {"stat": "popup_spawn_rate_multiplier", "value": 0.3}]}),
		_item("trial_version", "무료 체험판", "공격 간격 -35%, 60초 후 최대 HP -20", "Cursed", ["curse", "tempo"], {"effects": [{"stat": "attack_interval_multiplier", "value": -0.35}, {"type": "delayed_max_hp_loss", "value": 20, "delay": 60.0}]}),
		_item("suspicious_booster", "수상한 부스터", "이동속도 +40%, 팝업 드래그 속도 -25%", "Cursed", ["curse", "mobility"], {"effects": [{"stat": "move_speed_multiplier", "value": 0.4}, {"stat": "popup_drag_speed_multiplier", "value": -0.25}]}),
		_item("personal_data_sale", "개인정보 판매", "즉시 100G, 약관 팝업 등장률 증가", "Cursed", ["curse", "gold"], {"effects": [{"type": "gold", "value": 100}, {"stat": "terms_popup_weight_multiplier", "value": 0.35}]}),
		_item("close_button_addiction", "닫기 버튼 중독", "팝업을 닫을 때마다 +3G, 최대 팝업 +1", "Rare", ["popup", "gold"], {"effects": [{"stat": "gold_per_popup_close", "value": 3}, {"stat": "max_open_popups", "value": 1}]}),
		_item("compound_barrel", "복리 약실", "투자 중 골드 100G당 피해량 +6%, 최대 +36%", "Rare", ["investor", "damage"], {"stat": "invested_gold_damage_multiplier", "value": 0.06}),
		_item("credit_scope", "신용 조준경", "신용도 60 이상이면 사거리 +10%, 80 이상이면 +18%", "Rare", ["investor", "range"], {"stat": "credit_range_bonus", "value": 1}),
		_item("sponsor_rounds", "후원탄", "광고 완료 횟수 1회당 피해량 +8%, 최대 +160%", "Rare", ["sponsored", "damage"], {"stat": "sponsored_stack_damage_multiplier", "value": 0.08}),
		_item("banner_amp", "배너 증폭기", "스폰서 광고가 열려 있으면 공격 간격 -8%", "Rare", ["sponsored", "tempo"], {"stat": "sponsored_open_haste", "value": -0.08}),
		_item("popup_resonator", "팝업 공명기", "열린 팝업 1개당 공격 사거리 +3%, 최대 +18%", "Rare", ["clutter", "range"], {"stat": "popup_count_range_multiplier", "value": 0.03}),
		_item("overload_cache", "과밀 캐시", "열린 팝업이 5개 이상이면 피해량 +25%", "Epic", ["clutter", "damage"], {"stat": "overload_cache_damage_multiplier", "value": 0.25}),
		_item("focus_lens", "집중 렌즈", "열린 팝업이 1개 이하이면 사거리 +18%", "Rare", ["clean", "range"], {"stat": "focus_lens_range_multiplier", "value": 0.18}),
		_item("quiet_trigger", "정숙한 방아쇠", "열린 팝업이 0개이면 공격 간격 -18%", "Epic", ["clean", "tempo"], {"stat": "quiet_trigger_haste", "value": -0.18}),
		_item("empty_slot_charger", "정리 콤보", "정리 콤보가 유지되는 동안 콤보 1당 피해량 +2%, 최대 +20%", "Rare", ["clean", "damage"], {"stat": "cleanup_combo_damage_multiplier", "value": 0.02}),
		_item("close_combo", "닫기 콤보", "정리 콤보가 유지되는 동안 공격 간격 -15%", "Epic", ["clean", "tempo"], {"stat": "close_combo_haste", "value": -0.15}),
		_item("cleanup_routine_timer", "정리 루틴 타이머", "정리 콤보 유지시간 +1초", "Rare", ["clean"], {"stat": "cleanup_combo_grace_bonus", "value": 1}),
		_item("clean_route", "정리된 동선", "정리 콤보 유지 중 획득 범위 +40%", "Rare", ["clean", "pickup"], {"stat": "cleanup_combo_pickup_range_multiplier", "value": 0.4}),
		_item("heat_blade", "난이도 칼날", "난이도 1당 피해량 +5%, 대신 난이도가 3 이상이면 팝업 생성률 +10%", "Cursed", ["curse", "damage"], {"stat": "heat_damage_multiplier", "value": 0.05}),
		_item("cursed_cache", "저주 캐시", "즉시 60G를 얻지만 난이도 +1", "Cursed", ["curse", "gold"], {"effects": [{"type": "gold", "value": 60}, {"type": "heat", "value": 1}]}),
		_item("risky_wording", "위험 문구 강조", "현재 난이도 1당 치명타 피해 +6%", "Epic", ["curse", "crit"], {"stat": "crit_damage_per_difficulty", "value": 0.06}),
		_item("regeneration_patch", "재생 패치", "초당 체력 재생 +1.2", "Rare", ["health"], {"stat": "health_regen_per_second", "value": 1.2}),
		_item("vampire_chip", "흡혈 칩", "무기 피해의 2%를 체력으로 회복", "Rare", ["health"], {"stat": "life_steal_percent", "value": 0.02}),
		_item("emergency_blood_pack", "응급 혈액팩", "최대 HP +15, 즉시 15 회복", "Common", ["health"], {"effects": [{"stat": "max_hp", "value": 15}, {"type": "heal", "value": 15}]}),
		_item("wound_engine", "상처 엔진", "체력이 50% 이하이면 재생 +2/s, 30% 이하이면 공격 간격 -10%", "Epic", ["health", "tempo"], {"stat": "wound_engine", "value": 1}),
		_item("crimson_core", "진홍 코어", "흡혈량 +3%, 최대 HP 100당 피해량 +5%", "Epic", ["health", "damage"], {"stat": "life_steal_percent", "value": 0.03}),
		_item("cursed_transfusion", "저주 수혈", "최대 HP +50, 흡혈 +4%, 난이도 +1", "Cursed", ["curse", "health"], {"effects": [{"stat": "max_hp", "value": 50}, {"stat": "life_steal_percent", "value": 0.04}, {"type": "heat", "value": 1}]}),
	]

static func perks() -> Array:
	return [
		_item("faster_drag", "가벼운 창", "팝업 드래그가 더 가볍게 느껴집니다.", "Common", ["popup"], {"stat": "popup_drag_speed_multiplier", "value": 0.25}),
		_item("popup_spawn_down", "팝업 차단기", "팝업 생성률 -10%", "Common", ["popup"], {"stat": "popup_spawn_rate_multiplier", "value": -0.1}),
		_item("ad_profit", "광고 수익", "열린 광고 팝업이 시간에 따라 골드를 생성합니다.", "Rare", ["sponsored"], {"stat": "ad_gold_per_second", "value": 1}),
		_item("better_ad_buff", "스폰서 파워", "광고 버프 팝업 효과 +20%", "Rare", ["sponsored"], {"stat": "ad_buff_multiplier", "value": 0.2}),
		_item("shorter_timed_rewards", "빠른 수령", "시간 보상 팝업 완료 시간 -20%", "Common", ["popup"], {"stat": "timed_reward_duration_multiplier", "value": -0.2}),
		_item("popup_capacity", "어수선한 바탕화면", "최대 열린 팝업 +1", "Rare", ["popup"], {"stat": "max_open_popups", "value": 1}),
		_item("wide_safe_zone", "넓은 안전구역", "팝업이 플레이어 중심부를 더 넓게 피해서 생성됩니다.", "Common", ["popup"], {"stat": "safe_zone_multiplier", "value": 0.18}),
		_item("emergency_cooldown_down", "긴급 종료 단축", "Space 긴급 닫기 쿨타임 -20%", "Common", ["emergency"], {"stat": "emergency_cooldown_multiplier", "value": -0.2}),
		_item("terms_expert", "약관 전문가", "위험 약관 패널티를 1회 무효화합니다.", "Rare", ["terms"], {"stat": "terms_penalty_shield", "value": 1}),
		_item("cleanup_bonus", "창 정리 보너스", "팝업을 닫을 때마다 골드 +2", "Rare", ["popup", "gold"], {"stat": "gold_per_popup_close", "value": 2}),
		_item("sponsor_friendly", "스폰서 친화", "광고 버프 +25%, 팝업 생성률 +10%", "Rare", ["sponsored"], {"effects": [{"stat": "ad_buff_multiplier", "value": 0.25}, {"stat": "popup_spawn_rate_multiplier", "value": 0.1}]}),
		_item("multi_monitor", "멀티 모니터", "최대 팝업 +2, 팝업 4개 이상이면 골드 획득 +30%", "Epic", ["clutter"], {"effects": [{"stat": "max_open_popups", "value": 2}, {"stat": "crowded_gold_multiplier", "value": 0.3}]}),
		_item("task_manager", "작업 관리자", "긴급 닫기가 더 위험한 팝업을 우선 닫습니다.", "Epic", ["emergency"], {"stat": "smart_emergency_close", "value": 1}),
		_item("focus_mode", "집중 모드", "HP가 1이 되면 8초간 새 팝업 생성을 1회 중지합니다.", "Epic", ["health"], {"stat": "low_hp_popup_freeze", "value": 1}),
		_item("ad_addiction", "광고 중독", "광고 수익 2배, 팝업 생성률 +40%", "Cursed", ["curse", "sponsored"], {"effects": [{"stat": "ad_gold_multiplier", "value": 1.0}, {"stat": "popup_spawn_rate_multiplier", "value": 0.4}]}),
		_item("risky_clause_fan", "위험 조항 애호가", "약관 패널티를 받을 때마다 +60G", "Cursed", ["curse", "terms"], {"stat": "gold_per_terms_penalty", "value": 60}),
		_item("chaos_build", "난장판 빌드", "최대 팝업 +3, 팝업 5개 이상이면 아이템 가격 -20%", "Cursed", ["clutter"], {"effects": [{"stat": "max_open_popups", "value": 3}, {"stat": "crowded_item_discount", "value": 0.2}]}),
		_item("interest_vip", "이자 VIP", "이자 상품 출현률 +30%, 이자 지급 +20%", "Rare", ["investor"], {"effects": [{"stat": "interest_popup_weight_multiplier", "value": 0.3}, {"stat": "interest_payout_multiplier", "value": 0.2}]}),
		_item("popup_store_coupon", "팝업 스토어 쿠폰", "팝업 스토어 출현률 +30%, 상점 가격 -15%", "Rare", ["store"], {"effects": [{"stat": "popup_store_weight_multiplier", "value": 0.3}, {"stat": "popup_store_discount_multiplier", "value": 0.15}]}),
		_item("no_insurance", "보험 없는 삶", "긴급 닫기 비활성화, 보상 팝업 골드 +50%", "Cursed", ["curse", "reward"], {"effects": [{"stat": "emergency_close_disabled", "value": 1}, {"stat": "reward_gold_multiplier", "value": 0.5}]}),
	]

static func popup_definitions() -> Array:
	return [
		_popup("first_purchase_package", "첫 결제 패키지", "초기 플레이스타일 계약을 선택하세요.", "first_purchase_package", 0.0, 1),
		_popup("boss_package_ad", "보스 처치 패키지", "보스 보상 패키지를 골드로 구매할 수 있습니다.", "boss_package_ad", 0.0, 0),
		_popup("keyboard_security_installer", "키보드 보안 설치", "이동 입력을 안정화하는 보안 프로그램입니다.", "security_installer", 0.0, 0.7, {"program": "keyboard_security"}),
		_popup("realtime_guard_installer", "실시간 감시 설치", "일부 방해 팝업을 자동으로 감시합니다.", "security_installer", 0.0, 0.7, {"program": "realtime_guard"}),
		_popup("popup_quarantine_installer", "팝업 격리 설치", "위험 팝업을 주기적으로 격리합니다.", "security_installer", 0.0, 0.65, {"program": "popup_quarantine"}),
		_popup("kernel_guard_installer", "커널 보안 설치", "강력하지만 최대 체력을 예약합니다.", "security_installer", 0.0, 0.45, {"program": "kernel_guard"}),
		_popup("security_update_notice", "보안 업데이트 알림", "보안 프로그램이 추가 유지 비용을 요청합니다.", "security_update_notice", 9.0, 0.7),
		_popup("ad_buff", "전투 성능 스폰서", "유지 중 피해량이 증가하고 완료 시 골드가 지급됩니다.", "sponsored_ad", 20.0, 2.4, {"reward": {"type": "gold", "value": 24}, "open_buff": 0.15}),
		_popup("ad_coupon", "스폰서 할인 리워드", "완료 시 다음 아이템 머신 할인권을 지급합니다.", "sponsored_ad", 18.0, 1.9, {"reward": {"type": "item_discount", "value": 0.3, "uses": 1}}),
		_popup("ad_free_sample", "스폰서 무료 샘플", "완료 시 보급형 아이템 샘플을 지급합니다.", "sponsored_ad", 18.0, 1.55, {"reward": {"type": "free_sample_item", "rarity": "Common"}}),
		_popup("ad_premium_sample", "프리미엄 리워드 광고", "완료 시 다음 선택 보상을 확장합니다.", "sponsored_ad", 22.0, 1.25, {"reward": {"type": "extra_item_choice", "value": 1, "uses": 1}}),
		_popup("timed_reward", "전투 중 놓치면 손해", "이 창을 유지하면 제한 시간 후 소액 골드가 지급됩니다.", "timed_reward", 15.0, 1.6, {"reward": {"type": "gold", "value": 35}}),
		_popup("terms", "위험 조항 동의서", "안전 보상 또는 위험 보상과 패널티를 선택합니다.", "terms", 0.0, 1.15, {"safe_gold": 20, "risky_gold": 65, "penalty": {"stat": "terms_popup_weight_multiplier", "value": 0.35}}),
		_popup("terms_ad_tracking", "광고 추적 및 보상 약관", "스폰서 보상이 좋아지지만 광고 압박이 증가할 수 있습니다.", "terms", 0.0, 0.95, {"safe_gold": 18, "risky_stat": {"stat": "sponsored_reward_multiplier", "value": 0.25}, "penalty": {"stat": "sponsored_popup_weight_multiplier", "value": 0.35}}),
		_popup("terms_emergency_waiver", "긴급 닫기 포기 각서", "보상은 증가하나 긴급 대응 권한이 약해집니다.", "terms", 0.0, 0.85, {"safe_gold": 20, "risky_stat": {"stat": "reward_gold_multiplier", "value": 0.35}, "penalty": {"stat": "emergency_cooldown_multiplier", "value": 0.9}}),
		_popup("terms_malicious_optimization", "악성 최적화 동의서", "전투 효율을 얻지만 팝업 압박이 상승합니다.", "terms", 0.0, 0.65, {"safe_stat": {"stat": "damage_multiplier", "value": 0.12, "duration": 20.0}, "risky_stat": {"stat": "damage_multiplier", "value": 0.32, "duration": 28.0}, "penalty": {"stat": "popup_spawn_rate_multiplier", "value": 0.25}}),
		_popup("interest_offer", "단기 예치 상품 안내", "보유 골드 일부를 묶고 만기 후 이자를 받습니다.", "interest_offer", 0.0, 1.0),
		_popup("recurring_investment", "자동 적립 투자 설정", "새 골드 수익 일부를 자동 적립하고 만기 정산합니다.", "recurring_investment", 30.0, 0.8),
		_popup("loan_offer", "신용 현금화 제안", "신용도를 깎아 즉시 골드를 확보합니다.", "loan_offer", 0.0, 0.9),
		_popup("stock_broker_app", "팝업 증권 LIVE", "POP 팝업 테마주를 매매합니다.", "stock_broker_app", 0.0, 0.7),
		_popup("stock_stable", "안정 배당주", "낮은 변동성과 약한 상승 흐름을 가진 주식 안내입니다.", "stock_market", 12.0, 0.35, {"stock_kind": "stable"}),
		_popup("stock_momentum", "모멘텀 성장주", "변동성이 큰 성장주 안내입니다.", "stock_market", 12.0, 0.35, {"stock_kind": "momentum"}),
		_popup("stock_cursed", "저주 조작주", "고위험 주식 안내입니다. 손실 매도 시 난이도가 오릅니다.", "stock_market", 12.0, 0.2, {"stock_kind": "cursed"}),
		_popup("popup_store", "팝업 스토어", "등급별 미확인 아이템을 즉시 구매합니다.", "popup_store", 18.0, 0.9),
		_popup("clean_challenge_basic", "PC 정리 최적화 요청", "열린 창 수를 낮게 유지하면 할인 보상을 받습니다.", "clean_challenge", 10.0, 0.9, {"target_open_popups": 2, "reward": {"type": "item_discount", "value": 0.25, "uses": 1}}),
		_popup("volatile_bomb_popup", "긴급 최적화 스캔", "지금 닫으면 주변 적에게 폭발 피해를 줍니다.", "volatile_popup", 8.0, 0.8),
		_popup("moving_close", "떠다니는 광고 창", "화면을 떠다니는 추천 창입니다. 따라가서 닫아야 합니다.", "moving_close", 18.0, 0.75),
		_popup("infection", "무료 보안 확장 프로그램", "방치하면 유용한 팝업 하나를 오염시킵니다.", "infection", 7.5, 0.5),
	]

static func first_purchase_packages() -> Array:
	return [
		{"id": "sponsored_starter", "name": "스폰서 스타터 계약", "playstyle": "sponsored", "description": "광고를 열어둘수록 돈과 힘을 얻습니다.", "gold": 45, "effects": [{"stat": "sponsored_reward_multiplier", "value": 0.25}]},
		{"id": "clean_desk_starter", "name": "클린업 스타터 계약", "playstyle": "clean", "description": "팝업을 적게 유지하고 정리 콤보를 얻습니다.", "gold": 20, "effects": [{"stat": "cleanup_combo_grace_bonus", "value": 1.5}]},
		{"id": "clutter_chaos_starter", "name": "난장판 스타터 계약", "playstyle": "clutter", "description": "팝업을 열어둘수록 공격 속도와 보상이 좋아집니다.", "gold": 30, "effects": [{"stat": "max_open_popups", "value": 2}, {"stat": "crowded_gold_multiplier", "value": 0.2}]},
		{"id": "investor_starter", "name": "투자자 스타터 계약", "playstyle": "investor", "description": "예치와 주식 기능이 더 자주 등장합니다.", "gold": 60, "effects": [{"stat": "interest_popup_weight_multiplier", "value": 0.35}, {"stat": "interest_payout_multiplier", "value": 0.15}]},
		{"id": "risky_terms_starter", "name": "위험 계약자 스타터 계약", "playstyle": "curse", "description": "위험 약관과 난이도를 전투력으로 바꿉니다.", "gold": 80, "effects": [{"type": "heat", "value": 1}, {"stat": "heat_damage_multiplier", "value": 0.06}]},
	]

static func popup_store_catalog() -> Array:
	return [
		{"rarity": "Common", "label": "보급형 미확인 아이템", "price": 22},
		{"rarity": "Rare", "label": "희귀 미확인 아이템", "price": 48},
		{"rarity": "Epic", "label": "특급 미확인 아이템", "price": 88},
	]

static func attack_modules() -> Array:
	return [
		{"id": "ranged", "name": "원거리", "description": "가장 가까운 적을 자동 조준해 탄환을 발사합니다.", "base_form": "ranged_projectile"},
		{"id": "melee", "name": "근접", "description": "이동 방향 앞으로 짧고 강한 베기를 냅니다.", "base_form": "melee_forward_slash"},
		{"id": "aura", "name": "오라", "description": "원형 필드가 주기적으로 범위 피해를 줍니다.", "base_form": "aura_steady"},
		{"id": "deploy", "name": "설치", "description": "전방에 지뢰, 포탑, 장판을 설치합니다.", "base_form": "deploy_mine"},
	]

static func attack_forms() -> Array:
	return [
		_form("ranged_projectile", "기본 탄환", "가장 가까운 적을 자동 조준해 탄환을 발사합니다.", ["ranged"], ["projectile", "targeted"]),
		_form("ranged_scatter", "산탄", "자동 조준 방향으로 탄환 3발을 퍼뜨립니다.", ["ranged"], ["projectile", "scatter"]),
		_form("ranged_bounce", "반사탄", "첫 적중 후 주변 적에게 추가 연쇄 피해를 줍니다.", ["ranged"], ["projectile", "bounce"]),
		_form("ranged_laser", "레이저", "적 방향으로 즉시 관통 빔을 발사합니다.", ["ranged"], ["beam", "line"]),
		_form("ranged_charge_cannon", "집속포", "집속 후 큰 탄환을 방출해 폭발 피해를 줍니다.", ["ranged"], ["projectile", "charge", "area"]),
		_form("melee_forward_slash", "전방 참격", "전방 캡슐 범위를 베어냅니다.", ["melee"], ["melee", "line"]),
		_form("melee_circle_slash", "원형 베기", "주변 전체를 베어냅니다.", ["melee"], ["melee", "area"]),
		_form("melee_sword_wave", "검기", "전방으로 넓은 투사체를 날립니다.", ["melee"], ["melee", "projectile"]),
		_form("melee_dash_slash", "돌진 참격", "전방 긴 선분을 따라 강하게 베어냅니다.", ["melee"], ["melee", "dash", "line"]),
		_form("melee_charged_cleave", "모아베기", "짧게 힘을 모은 뒤 넓은 전방을 크게 베어냅니다.", ["melee"], ["melee", "charge", "area"]),
		_form("aura_steady", "지속 오라", "상시 링과 주기 피해를 유지합니다.", ["aura"], ["aura", "area"]),
		_form("aura_pulse", "맥동 오라", "느리지만 강한 오라 파동을 냅니다.", ["aura"], ["aura", "pulse", "area"]),
		_form("aura_infection", "감염 오라", "과밀 상태에서 더 강한 녹색 파동을 냅니다.", ["aura"], ["aura", "infection", "area"]),
		_form("aura_absorb", "흡수 오라", "오라 처치 시 소량의 골드를 흡수합니다.", ["aura"], ["aura", "area", "absorb"]),
		_form("aura_charged_nova", "집속 노바", "오라를 모았다가 넓은 폭발로 방출합니다.", ["aura"], ["aura", "charge", "area"]),
		_form("deploy_mine", "반응 지뢰", "적 접근 즉시 폭발하는 지뢰를 설치합니다.", ["deploy"], ["deploy", "mine", "explosion"]),
		_form("deploy_turret", "임시 포탑", "짧은 시간 자동 사격하는 포탑을 설치합니다.", ["deploy"], ["deploy", "turret", "projectile"]),
		_form("deploy_maturity_bomb", "만기 폭탄", "오래 유지될수록 강해지는 폭탄을 설치합니다.", ["deploy"], ["deploy", "bomb", "charge"]),
		_form("deploy_field", "장판 설치", "짧게 유지되는 피해 장판을 설치합니다.", ["deploy"], ["deploy", "area", "field"]),
	]

static func attack_mechanics() -> Array:
	return [
		{"id": "bounce_plus", "name": "추가 반사", "description": "반사형 공격의 연쇄 횟수 +1", "compatible_tags": ["projectile", "bounce"]},
		{"id": "overcharge", "name": "과충전", "description": "충전형 공격의 피해와 범위 증가", "compatible_tags": ["charge"]},
		{"id": "kill_chain", "name": "처치 연쇄", "description": "처치한 적 주변에 작은 폭발", "compatible_tags": ["projectile", "beam", "melee", "area", "aura"]},
		{"id": "popup_close_trigger", "name": "닫기 연계", "description": "팝업을 닫으면 다음 1차 공격 피해 +25%", "compatible_tags": ["any"]},
		{"id": "pierce", "name": "관통", "description": "투사체 관통 +1, 빔 폭 증가", "compatible_tags": ["projectile", "beam"]},
	]

static func build_scalings() -> Array:
	return [
		_scaling("investor_capital_amplifier", "자본 증폭", "investor", "투자 중 골드가 주 공격 피해를 증폭합니다."),
		_scaling("investor_credit_precision", "신용 정밀화", "investor", "신용도가 높을수록 쿨타임이 감소합니다."),
		_scaling("investor_reserve_range", "비상금 사거리", "investor", "보유 골드가 사거리를 넓힙니다."),
		_scaling("sponsored_overcharge", "후원탄 보급", "sponsored", "광고 완료 횟수가 피해를 올립니다."),
		_scaling("sponsored_brand_expansion", "브랜드 확장", "sponsored", "열린 광고 수가 범위를 넓힙니다."),
		_scaling("sponsored_monetization", "광고 수익화", "sponsored", "광고 완료 기록이 쿨타임을 줄입니다."),
		_scaling("clutter_resonance", "과밀 공명", "clutter", "열린 팝업 수가 범위와 피해를 올립니다."),
		_scaling("clutter_noise_amplifier", "잡음 증폭", "clutter", "과밀 상태에서 판정이 넓어집니다."),
		_scaling("clutter_adaptation", "혼잡 적응", "clutter", "열린 팝업 수가 쿨타임을 줄입니다."),
		_scaling("clean_precision", "집중 사격", "clean", "팝업이 적을수록 피해와 사거리가 증가합니다."),
		_scaling("clean_clear_sight", "깨끗한 시야", "clean", "팝업이 적을수록 판정이 안정됩니다."),
		_scaling("cleanup_combo_precision", "정리된 루틴", "clean", "정리 콤보가 범위와 쿨타임을 개선합니다."),
		_scaling("curse_heat_overload", "약관 폭주", "curse", "난이도가 피해와 치명타 피해로 전환됩니다."),
		_scaling("risk_liability_waiver", "책임 면책", "curse", "최근 피해와 약관 패널티가 방어 보정이 됩니다."),
		_scaling("risk_premium", "위험 프리미엄", "curse", "높은 난이도가 범위와 보상을 높입니다."),
		_scaling("generic_stable_output", "안정 출력", "generic", "피해, 사거리, 쿨타임을 균형 있게 개선합니다."),
		_scaling("generic_expanded_ballistics", "확장 탄도", "generic", "사거리와 투사체/빔 판정을 넓힙니다."),
		_scaling("generic_combat_maintenance", "전투 정비", "generic", "쿨타임과 생존 보조를 개선합니다."),
		_scaling("gold_reserve_range", "비상금 사거리", "generic", "보유 골드가 사거리를 증가시킵니다."),
	]

static func deepening_options() -> Array:
	return [
		{"id": "power", "name": "화력형", "description": "해당 모듈 피해량 +30%", "damage": 0.3},
		{"id": "tempo", "name": "빈도형", "description": "해당 모듈 쿨타임 -20%", "cooldown": -0.2},
		{"id": "area", "name": "범위형", "description": "해당 모듈 범위 +25%", "range": 0.25},
	]

static func synergy_options() -> Array:
	return [
		{"id": "popup_trigger", "name": "창 닫기 연계", "description": "팝업을 닫을 때 1차 공격이 즉시 발동합니다."},
		{"id": "secondary_haste", "name": "보조 적중 가속", "description": "보조 공격이 명중하면 1차 공격 쿨타임을 줄입니다."},
		{"id": "primary_charge", "name": "처치 충전", "description": "1차 공격 처치가 보조 공격을 충전합니다."},
	]

static func difficulty_stages() -> Array:
	return [
		{"id": "normal", "label": "정상 작동", "min": 0.0},
		{"id": "warning", "label": "경고", "min": 2.0},
		{"id": "danger", "label": "위험", "min": 4.0},
		{"id": "overload", "label": "과부하", "min": 7.0},
		{"id": "collapse", "label": "시스템 붕괴", "min": 11.0},
		{"id": "nightmare", "label": "관리자 권한 상실", "min": 16.0},
	]

static func wave_modes() -> Array:
	return [
		{"id": "normal", "label": "일반 밀도", "duration": [10.0, 16.0], "spawn_multiplier": 1.0, "hp_multiplier": 1.0, "speed_multiplier": 1.0, "pattern": "around", "intense": false},
		{"id": "side_push", "label": "한쪽 압박", "duration": [8.0, 12.0], "spawn_multiplier": 1.25, "hp_multiplier": 1.0, "speed_multiplier": 1.0, "pattern": "side", "intense": true},
		{"id": "surround", "label": "포위 압박", "duration": [7.0, 11.0], "spawn_multiplier": 1.35, "hp_multiplier": 0.95, "speed_multiplier": 1.0, "pattern": "ring", "intense": true},
		{"id": "fast_horde", "label": "빠른 물결", "duration": [6.0, 9.0], "spawn_multiplier": 1.3, "hp_multiplier": 0.75, "speed_multiplier": 1.28, "pattern": "around", "intense": true},
		{"id": "dense_horde", "label": "두꺼운 물결", "duration": [8.0, 12.0], "spawn_multiplier": 0.95, "hp_multiplier": 1.45, "speed_multiplier": 0.82, "pattern": "around", "intense": true},
		{"id": "breather", "label": "정리 구간", "duration": [5.0, 8.0], "spawn_multiplier": 0.65, "hp_multiplier": 0.9, "speed_multiplier": 0.9, "pattern": "around", "intense": false},
	]

static func security_programs() -> Array:
	return [
		{"type": "keyboard_security", "name": "키보드 보안", "description": "이동 속도 패널티가 작고 긴급 닫기 쿨타임을 낮춥니다.", "cost": 35, "move_penalty": 0.02, "reserved_hp": 0, "effect": {"stat": "emergency_cooldown_multiplier", "value": -0.12}},
		{"type": "realtime_guard", "name": "실시간 감시", "description": "일정 시간마다 방해 팝업을 자동 정리합니다.", "cost": 45, "move_penalty": 0.04, "reserved_hp": 0, "effect": {"stat": "auto_close_basic_interval", "value": 6}},
		{"type": "popup_quarantine", "name": "팝업 격리소", "description": "감염/이동 팝업을 우선 제거합니다.", "cost": 55, "move_penalty": 0.05, "reserved_hp": 8, "effect": {"stat": "smart_emergency_close", "value": 1}},
		{"type": "kernel_guard", "name": "커널 보안", "description": "최대 HP를 예약하지만 위험 팝업을 주기적으로 정리합니다.", "cost": 75, "move_penalty": 0.07, "reserved_hp": 16, "effect": {"stat": "low_hp_popup_freeze", "value": 1}},
	]

static func _item(id: String, name: String, description: String, rarity: String, tags: Array, effect: Dictionary) -> Dictionary:
	var result = {
		"id": id,
		"name": name,
		"description": description,
		"rarity": rarity,
		"tags": tags,
	}
	for key in effect.keys():
		result[key] = effect[key]
	return result

static func _popup(id: String, title: String, body: String, type: String, duration: float, weight: float, extra = {}) -> Dictionary:
	var result = {
		"id": id,
		"title": title,
		"body": body,
		"type": type,
		"duration": duration,
		"weight": weight,
	}
	for key in extra.keys():
		result[key] = extra[key]
	return result

static func _form(id: String, name: String, description: String, modules: Array, tags: Array) -> Dictionary:
	return {
		"id": id,
		"name": name,
		"description": description,
		"compatible_modules": modules,
		"tags": tags,
	}

static func _scaling(id: String, name: String, playstyle: String, description: String) -> Dictionary:
	return {
		"id": id,
		"name": name,
		"playstyle": playstyle,
		"description": description,
		"compatible_tags": ["any"],
	}

