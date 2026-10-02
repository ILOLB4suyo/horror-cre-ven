extends Interactable


@export var item_id: String = ""


func interact(player) -> void:
	player.add_item(item_id)
	queue_free()
