
extends CanvasLayer

@onready var pause_background = $PauseBg
@onready var pause_menu = $PauseMenu
@onready var continue_button = $PauseMenu/Continue
@onready var exit_button = $PauseMenu/Exit

var is_paused = false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

	pause_background.z_index = 0
	pause_menu.z_index = 10

	pause_background.hide()
	pause_menu.hide()

	continue_button.pressed.connect(_on_continue_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()
		get_viewport().set_input_as_handled()

func toggle_pause():
	is_paused = !is_paused
	get_tree().paused = is_paused

	pause_background.visible = is_paused
	pause_menu.visible = is_paused

	if is_paused:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	print("Mouse Mode: ", Input.mouse_mode)
	print("Game Paused: ", get_tree().paused)

func _on_continue_pressed():
	is_paused = false
	get_tree().paused = false

	pause_background.hide()
	pause_menu.hide()

	await get_tree().process_frame
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	print("After continue: ", Input.mouse_mode)

func _on_exit_pressed():
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
