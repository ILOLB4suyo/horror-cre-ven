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
@onready var retry_button: Button = $DeathOverlay/DeathPanel/CenterContainer/VBoxContainer/RetryButton



func _ready() -> void:
	death_overlay.visible = false
	death_panel.visible = false

	jumpscare_video.finished.connect(_on_jumpscare_finished)
	retry_button.pressed.connect(_on_retry_pressed)
	



func play_death_sequence(video: VideoStream) -> void:
	if video == null:
		push_error("HUD: Video jumpscare belum diberikan.")
		return

	death_overlay.visible = true
	death_panel.visible = false

	jumpscare_video.stream = video
	jumpscare_video.visible = true
	jumpscare_video.play()

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_jumpscare_finished() -> void:
	jumpscare_video.stop()
	jumpscare_video.visible = false

	death_panel.visible = true

	print("JUMPSCARE FINISHED - SHOW DEATH SCREEN")


func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()


func _process(_delta: float) -> void:
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
