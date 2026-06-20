extends RefCounted
class_name PopupClosePolicy

const NORMAL := "normal"
const MINIMIZE_ONLY := "minimize_only"
const FORCED_CHOICE := "forced_choice"
const INTERNAL_RESOLVE := "internal_resolve"
const AUTO_CLOSE := "auto_close"
const INPUT_GRACE := "input_grace"

static func policy_for(popup: Dictionary) -> String:
	var type = popup.get("def", {}).get("type", "")
	if type == "stock_broker_app":
		return MINIMIZE_ONLY
	if type == "first_purchase_package":
		return FORCED_CHOICE
	if popup.get("locked", false):
		return INTERNAL_RESOLVE
	if type == "interest_offer" and popup.get("interestAccepted", false) and not popup.get("interestMatured", false):
		return INTERNAL_RESOLVE
	if type == "recurring_investment" and popup.has("investment") and popup.investment.get("accepted", false) and not popup.investment.get("matured", false):
		return INTERNAL_RESOLVE
	if type == "stock_market" and popup.has("stock") and popup.stock.get("invested", false):
		return INTERNAL_RESOLVE
	if popup.get("inputGrace", 0.0) > 0.0:
		return INPUT_GRACE
	if popup.get("def", {}).get("autoClose", 0.0) > 0.0:
		return AUTO_CLOSE
	return NORMAL
