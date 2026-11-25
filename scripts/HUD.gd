extends CanvasLayer


@onready var player = $"../Player"

@onready var stamina_bar: ProgressBar = $StaminaUI/StaminaBar
@onready var crouch_indicator: TextureRect = $CrouchIndicator
@onready var interaction_progress: ProgressBar = $InteractionProgress
@onready var interaction_label: Label = $InteractionProgress/InteractionLabel

@onready var document_overlay: Control = $DocumentOverlay
@onready var document_title: Label = $DocumentOverlay/DocumentPanel/Title
@onready var document_content: RichTextLabel = $DocumentOverlay/DocumentPanel/Content

@onready var death_overlay: Control = $DeathOverlay
@onready var jumpscare_video: VideoStreamPlayer = $DeathOverlay/JumpscareVideo
@onready var death_panel: Control = $DeathOverlay/DeathPanel
@onready var retry_button: Button = $DeathOverlay/DeathPanel/CenterContainer/VBoxContainer/MainMenuButton

@onready var jumpscare_audio: AudioStreamPlayer = $JumpscareAudio

func _ready() -> void:
	death_overlay.visible = false
	death_panel.visible = false

	death_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	death_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	jumpscare_video.mouse_filter = Control.MOUSE_FILTER_IGNORE

	retry_button.mouse_filter = Control.MOUSE_FILTER_STOP
	retry_button.disabled = false
	retry_button.focus_mode = Control.FOCUS_ALL

	jumpscare_video.finished.connect(_on_jumpscare_finished)
	retry_button.pressed.connect(_on_retry_pressed)

	retry_button.mouse_entered.connect(
		func():
			print("DEBUG: MOUSE ENTERED RETRY BUTTON")
	)

	print("DEBUG: HUD READY - RETRY SIGNAL CONNECTED")



func play_death_sequence(video: VideoStream) -> void:
	if video == null:
		push_error("HUD: Video jumpscare belum diberikan.")
		return

	death_overlay.visible = true
	death_panel.visible = false


	jumpscare_audio.stop()
	jumpscare_audio.play()


	jumpscare_video.stream = video
	jumpscare_video.visible = true
	jumpscare_video.play()

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_jumpscare_finished() -> void:
	jumpscare_video.stop()
	jumpscare_video.hide()

	death_panel.show()

	retry_button.show()
	retry_button.disabled = false
	retry_button.mouse_filter = Control.MOUSE_FILTER_STOP

	print("JUMPSCARE FINISHED - SHOW DEATH SCREEN")
	print("Retry visible: ", retry_button.visible)
	print("Retry global position: ", retry_button.global_position)
	print("Retry size: ", retry_button.size)
	print("Retry global rect: ", retry_button.get_global_rect())

	retry_button.grab_focus()


func _on_retry_pressed() -> void:
	print("DEBUG: MAIN MENU BUTTON PRESSED")

	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	var error := get_tree().change_scene_to_file(
        "res://scenes/MainMenu.tscn"
	)

	if error != OK:
		push_error("HUD: Gagal kembali ke Main Menu. Error: %s" % error)


func _process(_delta: float) -> void:
	if not is_instance_valid(player):
		return

	stamina_bar.max_value = player.max_stamina
	stamina_bar.value = player.stamina

	crouch_indicator.visible = (
		player.movement_state == player.MovementState.SNEAKING
	)


func show_interaction_prompt(text: String) -> void:
	interaction_progress.visible = true
	interaction_label.visible = true
	interaction_label.text = text


func hide_interaction_prompt() -> void:
	interaction_progress.visible = false
	interaction_label.visible = false
	interaction_progress.value = 0.0
	interaction_label.text = ""


func set_interaction_progress(progress: float) -> void:
	interaction_progress.value = progress


func show_document(title: String, content: String) -> void:
	document_title.text = title
	document_content.text = content

	document_overlay.visible = true

func hide_document() -> void:
	document_overlay.visible = false

func show_death_screen() -> void:
	death_overlay.visible = true

	jumpscare_video.stop()
	jumpscare_video.visible = false

	death_panel.visible = true

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
