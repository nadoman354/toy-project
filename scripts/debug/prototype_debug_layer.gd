extends CanvasLayer
class_name PrototypeDebugLayer

var root: Control

func setup(_game_root) -> void:
	layer = 40
	root = get_node_or_null("DebugRoot")
	if root == null:
		root = Control.new()
		root.name = "DebugRoot"
		root.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(root)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE

func debug_parent() -> Control:
	return root
