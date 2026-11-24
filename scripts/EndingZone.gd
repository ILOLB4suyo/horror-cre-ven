
extends Area3D

@onready var fade_rect: ColorRect = $"../EndingScreen/FadeRect"

@onready var ending_label: Label = $"../EndingScreen/FadeRect/CenterContainer/VBoxContainer/Label"

@onready var ending_subtitle: Label = $"../EndingScreen/FadeRect/CenterContainer/VBoxContainer/Label2"

@onready var replay_button: Button = $"../EndingScreen/FadeRect/CenterContainer/VBoxContainer/MainMenuButton"

@export_group("Fade")
@export var fade_duration: float = 2.0

var ending_started: bool = false


func _ready() -> void:
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ignore_mouse_recursive(fade_rect)

	body_entered.connect(_on_body_entered)
	replay_button.pressed.connect(_on_replay_pressed)

	fade_rect.color = Color(0, 0, 0, 0)

	ending_label.hide()
	ending_subtitle.hide()
	replay_button.hide()

	print("ENDING ZONE READY")


func _ignore_mouse_recursive(node: Node) -> void:
	for child in node.get_children():
		if child is Button:
			continue

		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE

		_ignore_mouse_recursive(child)

func _on_body_entered(body: Node3D) -> void:
	print("ENDING ZONE: BODY DETECTED: ", body.name)
	print("BODY GROUPS: ", body.get_groups())

	if ending_started:
		print("ENDING SUDAH DIMULAI")
		return

	if not body.is_in_group("player"):
		print("BODY BUKAN PLAYER!")
		return

	print("PLAYER BERHASIL TERDETEKSI")

	if body.is_won or body.is_dead:
		print("PLAYER SUDAH WON ATAU DEAD")
		return

	ending_started = true

	print("MEMANGGIL COMPLETE ENDING")

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
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
