extends Interactable

signal lift_opened

@export_group("Monster2 Spawn")
@export var monster2_scene: PackedScene
@export var monster2_spawn_point: Node3D

var monster2_spawned: bool = false



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

func spawn_monster2() -> void:
	if monster2_spawned:
		return

	if monster2_scene == null:
		push_error("LiftDoor: Monster2 scene belum diatur.")
		return

	var monster := monster2_scene.instantiate()

	get_tree().current_scene.add_child(monster)

	if monster2_spawn_point != null:
		monster.global_position = monster2_spawn_point.global_position

	monster2_spawned = true
	print("LiftDoor: Monster2 spawned.")


func can_interact(player) -> bool:
	if is_open:
		return false

	return player.has_item(required_item_id)


func get_interaction_text(player) -> String:
	if is_open:
		return ""

	if not player.has_item(required_item_id):
		return "LOCKED"

	return "HOLD F"


func interact(player: Node) -> void:
	if is_open:
		return

	if not player.has_item(required_item_id):
		return

	is_open = true

	lift_opened.emit()
	spawn_monster2()
	
	
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
