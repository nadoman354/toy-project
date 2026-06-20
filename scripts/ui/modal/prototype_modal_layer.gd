extends CanvasLayer
class_name PrototypeModalLayer

var root: Control

func setup(_game_root) -> void:
	layer = 50
	root = get_node_or_null("ModalRoot")
	if root == null:
		root = Control.new()
		root.name = "ModalRoot"
		root.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(root)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE

func choice_parent() -> Control:
	return root
