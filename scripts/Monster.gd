
extends CharacterBody3D

enum MonsterState {
	PATROL,
	CHASE,
	DEAD
}

@export_group("Movement")
@export var patrol_speed: float = 2.0
@export var chase_speed: float = 4.5
@export var gravity: float = 9.8
@export var rotation_speed: float = 5.0

@export_group("Detection")
@export var detection_range: float = 10.0
@export var lose_target_range: float = 15.0
@export var catch_distance: float = 1.2

@export_group("Patrol")
@export var patrol_points: Array[Node3D] = []

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D

var current_state: MonsterState = MonsterState.PATROL
var player: CharacterBody3D
var patrol_index: int = 0


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player") as CharacterBody3D

	if player == null:
		push_error("Monster: Player tidak ditemukan dalam group 'player'.")
		return

	navigation_agent.path_desired_distance = 0.5
	navigation_agent.target_desired_distance = 0.8

	# Tunggu navigation map siap.
	await get_tree().physics_frame

	if patrol_points.size() > 0:
		set_patrol_target()


func _physics_process(delta: float) -> void:
	if current_state == MonsterState.DEAD:
		velocity = Vector3.ZERO
		return

	if player == null or not is_instance_valid(player):
		velocity = Vector3.ZERO
		move_and_slide()
		return

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	update_state()

	match current_state:
		MonsterState.PATROL:
			patrol(delta)

		MonsterState.CHASE:
			chase_player(delta)

	move_and_slide()


func update_state() -> void:
	if player == null or not is_instance_valid(player):
		return

	var distance_to_player := global_position.distance_to(
		player.global_position
	)

	if current_state == MonsterState.PATROL:
		if distance_to_player <= detection_range:
			current_state = MonsterState.CHASE
			navigation_agent.target_position = player.global_position
			print("Monster: PLAYER DETECTED - CHASING")

	elif current_state == MonsterState.CHASE:


		if distance_to_player <= catch_distance:
			catch_player()
			return

		if distance_to_player >= lose_target_range:
			current_state = MonsterState.PATROL
			set_patrol_target()
			print("Monster: PLAYER LOST - RETURNING TO PATROL")


func patrol(delta: float) -> void:
	if patrol_points.is_empty():
		velocity.x = 0.0
		velocity.z = 0.0
		return

	if navigation_agent.is_navigation_finished():
		patrol_index = (patrol_index + 1) % patrol_points.size()
		set_patrol_target()

	move_toward_target(patrol_speed, delta)


func chase_player(delta: float) -> void:
	# Perbarui tujuan pengejaran.
	navigation_agent.target_position = player.global_position

	move_toward_target(chase_speed, delta)


func move_toward_target(speed: float, delta: float) -> void:
	if navigation_agent.is_navigation_finished():
		velocity.x = 0.0
		velocity.z = 0.0
		return

	var next_position := navigation_agent.get_next_path_position()
	var direction := next_position - global_position

	direction.y = 0.0
	direction = direction.normalized()

	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	if direction.length_squared() > 0.001:
		var target_angle := atan2(-direction.x, -direction.z)
		rotation.y = lerp_angle(
			rotation.y,
			target_angle,
			1.0 - exp(-rotation_speed * delta)
		)


func set_patrol_target() -> void:
	if patrol_points.is_empty():
		return

	if patrol_index >= patrol_points.size():
		patrol_index = 0

	var point := patrol_points[patrol_index]

	if is_instance_valid(point):
		navigation_agent.target_position = point.global_position


func catch_player() -> void:
	if current_state == MonsterState.DEAD:
		return

	current_state = MonsterState.DEAD
	velocity = Vector3.ZERO

	print("Monster: PLAYER CAUGHT")

	if player.has_method("die"):
		player.die()
