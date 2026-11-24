
extends Area3D

@export_group("Ending UI")
@export var fade_rect: ColorRect
@export var ending_label: Label
@export var ending_subtitle: Label
@export var replay_button: Button

@export_group("Fade")
@export var fade_duration: float = 2.0

var ending_started: bool = false


func _ready() -> void:
	if fade_rect == null:
		push_error("EndingZone: FadeRect belum diatur.")
		return
	
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ignore_mouse_recursive(fade_rect) 
	
	if ending_label == null:
		push_error("EndingZone: Ending Label belum diatur.")
		return

	if ending_subtitle == null:
		push_error("EndingZone: Label2 belum diatur.")
		return

	if replay_button == null:
		push_error("EndingZone: Replay Button belum diatur.")
		return

	body_entered.connect(_on_body_entered)
	replay_button.pressed.connect(_on_replay_pressed)

	fade_rect.color = Color(0, 0, 0, 0)

	ending_label.hide()
	ending_subtitle.hide()
	replay_button.hide()


func _ignore_mouse_recursive(node: Node) -> void:
	for child in node.get_children():
		if child is Button:
			continue

		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE

		_ignore_mouse_recursive(child)

func _on_body_entered(body: Node3D) -> void:
	if ending_started:
		return

	if not body.is_in_group("player"):
		return

	if body.is_won or body.is_dead:
		return

	ending_started = true


	body.complete_ending()

	await play_ending()


func play_ending() -> void:
	fade_rect.show()

	var tween := create_tween()
	tween.tween_property(
		fade_rect,
		"color:a",
		1.0,
		fade_duration
	)

	await tween.finished

	ending_label.show()
	ending_subtitle.show()
	replay_button.show()


func _on_replay_pressed() -> void:
	get_tree().reload_current_scene()
