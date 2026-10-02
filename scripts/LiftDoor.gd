extends Interactable


@export var required_item_id: String = ""
@export var slide_distance: float = 1.0
@export var open_speed: float = 5.0

var is_open: bool = false

var left_closed_position: Vector3
var right_closed_position: Vector3

var left_target_position: Vector3
var right_target_position: Vector3

var left_closed_collision_position: Vector3
var right_closed_collision_position: Vector3

var left_target_collision_position: Vector3
var right_target_collision_position: Vector3


@onready var left_panel: Node3D = $LeftPanel
@onready var right_panel: Node3D = $RightPanel

@onready var left_collision: CollisionShape3D = $LeftCollision
@onready var right_collision: CollisionShape3D = $RightCollision


func _ready() -> void:
	left_closed_position = left_panel.position
	right_closed_position = right_panel.position

	left_target_position = left_closed_position
	right_target_position = right_closed_position

	left_closed_collision_position = left_collision.position
	right_closed_collision_position = right_collision.position

	left_target_collision_position = left_closed_collision_position
	right_target_collision_position = right_closed_collision_position


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

	left_target_position = left_closed_position
	left_target_position.x -= slide_distance

	right_target_position = right_closed_position
	right_target_position.x += slide_distance

	left_target_collision_position = left_closed_collision_position
	left_target_collision_position.x -= slide_distance

	right_target_collision_position = right_closed_collision_position
	right_target_collision_position.x += slide_distance


func _process(delta: float) -> void:
	var weight := 1.0 - exp(-open_speed * delta)

	left_panel.position = left_panel.position.lerp(
		left_target_position,
		weight
	)

	right_panel.position = right_panel.position.lerp(
		right_target_position,
		weight
	)

	left_collision.position = left_collision.position.lerp(
		left_target_collision_position,
		weight
	)

	right_collision.position = right_collision.position.lerp(
		right_target_collision_position,
		weight
	)
