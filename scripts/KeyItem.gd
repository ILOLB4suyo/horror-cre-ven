
extends Interactable

@export var item_id: String = ""

@export_group("Stalker Spawn")
@export var spawn_stalker_on_pickup: bool = false
@export var stalker_scene: PackedScene
@export var stalker_spawn_point: Marker3D

@export var stalker_patrol_points: Array[Node3D] = []

func interact(player) -> void:
	player.add_item(item_id)

	if spawn_stalker_on_pickup:
		spawn_stalker()

	queue_free()


func spawn_stalker() -> void:
	if stalker_scene == null:
		push_error("KeyItem: Stalker Scene belum diatur.")
		return

	if stalker_spawn_point == null:
		push_error("KeyItem: Stalker Spawn Point belum diatur.")
		return

	var stalker = stalker_scene.instantiate()

	get_tree().current_scene.add_child(stalker)

	stalker.global_position = stalker_spawn_point.global_position
	stalker.patrol_points = stalker_patrol_points

	print("KeyItem: STALKER SPAWNED")
