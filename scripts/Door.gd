extends Interactable


@export var required_item_id: String = ""
@export var open_speed: float = 5.0

var is_open: bool = false

@export var open_angle: float = 90.0

var closed_rotation: float
var target_rotation: float


func _ready() -> void:
	closed_rotation = rotation.y
	target_rotation = closed_rotation


func can_interact(player) -> bool:
	if is_open:
		return false

	return player.has_item(required_item_id)

func get_interaction_text(player) -> String:
	if is_open:
		return ""

	if not player.has_item(required_item_id):
		return "LOCKED"

	return "HOLD E"


func interact(player: Node) -> void:
	if is_open:
		return

	if not player.has_item(required_item_id):
		return

	is_open = true

	target_rotation = closed_rotation + deg_to_rad(open_angle)


func _process(delta: float) -> void:
	rotation.y = lerp_angle(
		rotation.y,
		target_rotation,
		1.0 - exp(-open_speed * delta)
	)
