extends Interactable


@export var document_title: String = "Document"
@export_multiline var document_content: String = ""

@export var interaction_text: String = "READ"


func can_interact(player) -> bool:
	return not player.is_reading


func get_interaction_text(player) -> String:
	if player.is_reading:
		return ""

	return interaction_text


func interact(player: Node) -> void:
	player.open_document(
		document_title,
		document_content
	)
