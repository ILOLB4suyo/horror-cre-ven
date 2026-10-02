extends CanvasLayer


@onready var player = $"../Player"

@onready var stamina_bar: ProgressBar = $StaminaUI/StaminaBar
@onready var crouch_indicator: TextureRect = $CrouchIndicator
@onready var interaction_progress: ProgressBar = $InteractionProgress
@onready var interaction_label: Label = $InteractionProgress/InteractionLabel

@onready var document_overlay: Control = $DocumentOverlay
@onready var document_title: Label = $DocumentOverlay/DocumentPanel/Title
@onready var document_content: RichTextLabel = $DocumentOverlay/DocumentPanel/Content

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
