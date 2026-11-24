
extends Interactable

@export var item_id: String = ""

@export_group("Random Keycard Spawn")
@export var keycard_spawn_points: Array[Marker3D] = []

@export_group("Stalker Spawn")
@export var spawn_stalker_on_pickup: bool = false
@export var stalker_scene: PackedScene
@export var stalker_spawn_point: Marker3D
@export var stalker_patrol_points: Array[Node3D] = []

@export_group("Monster2 Spawn")
@export var spawn_monster2_on_pickup: bool = false
@export var monster2_scene: PackedScene
@export var monster2_spawn_point: Marker3D


func _ready() -> void:
	randomize()
	spawn_keycard_at_random_location()


func spawn_keycard_at_random_location() -> void:
	if keycard_spawn_points.is_empty():
		push_error("KeyItem: Belum ada lokasi spawn KeyCard.")
		return

	var valid_points: Array[Marker3D] = []

	for point in keycard_spawn_points:
		if is_instance_valid(point):
			valid_points.append(point)

	if valid_points.is_empty():
		push_error("KeyItem: Tidak ada Spawn Point yang valid.")
		return

	var random_index := randi_range(0, valid_points.size() - 1)
	var selected_point := valid_points[random_index]

	global_position = selected_point.global_position

	print("KeyItem: KeyCard spawned at ", selected_point.name)


func interact(player) -> void:
	player.add_item(item_id)

	if spawn_stalker_on_pickup:
		spawn_stalker()

	if spawn_monster2_on_pickup:
		spawn_monster2()

	queue_free()


func spawn_stalker() -> void:
	if stalker_scene == null:
		push_error("KeyItem: Stalker Scene belum diatur.")
		return

	if stalker_spawn_point == null:
		push_error("KeyItem: Stalker Spawn Point belum diatur.")
		return

	var stalker = stalker_scene.instantiate()

	print("DEBUG: Scene yang di-spawn = ", stalker_scene.resource_path)
	print("DEBUG: Script yang digunakan = ", stalker.get_script().resource_path)

	get_tree().current_scene.add_child(stalker)

	stalker.global_position = stalker_spawn_point.global_position
	stalker.patrol_points = stalker_patrol_points

	print("KeyItem: STALKER SPAWNED")



func spawn_monster2() -> void:
	if monster2_scene == null:
		push_error("KeyItem: Monster2 Scene belum diatur.")
		return

	if monster2_spawn_point == null:
		push_error("KeyItem: Monster2 Spawn Point belum diatur.")
		return

	var monster2 = monster2_scene.instantiate()

	get_tree().current_scene.add_child(monster2)

	monster2.global_position = monster2_spawn_point.global_position

	print("KeyItem: MONSTER2 SPAWNED")
