
extends CharacterBody3D

enum Monster2State {
	FOLLOW,
	CAUGHT
}

@export_group("Follow")
@export var follow_delay: float = 3.0
@export var follow_speed: float = 3.0
@export var rotation_speed: float = 5.0
@export var gravity: float = 9.8
@export var catch_distance: float = 1.2

@export_group("Trail")
@export var sample_interval: float = 0.05
@export var repath_interval: float = 0.2

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D

var player: CharacterBody3D
var current_state: Monster2State = Monster2State.FOLLOW

var elapsed_time: float = 0.0
var sample_timer: float = 0.0
var repath_timer: float = 0.0

var trail_times: Array[float] = []
var trail_positions: Array[Vector3] = []


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player") as CharacterBody3D

	if player == null:
		push_error("Monster2: Player tidak ditemukan dalam group 'player'.")
		set_physics_process(false)
		return

	navigation_agent.path_desired_distance = 0.5
	navigation_agent.target_desired_distance = 0.8

	last_stuck_check_position = global_position

	await get_tree().physics_frame


var last_stuck_check_position: Vector3 = Vector3.ZERO


func _physics_process(delta: float) -> void:
	if current_state == Monster2State.CAUGHT:
		velocity = Vector3.ZERO
		return

	if player == null or not is_instance_valid(player):
		velocity = Vector3.ZERO
		move_and_slide()
		return

	elapsed_time += delta
	sample_timer -= delta
	repath_timer -= delta

	if sample_timer <= 0.0:
		record_player_position()
		sample_timer = sample_interval

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	follow_delayed_position(delta)
	move_and_slide()

	var horizontal_distance := Vector2(
		global_position.x - player.global_position.x,
		global_position.z - player.global_position.z
	).length()

	if horizontal_distance <= catch_distance:
		catch_player()


func record_player_position() -> void:
	trail_times.append(elapsed_time)
	trail_positions.append(player.global_position)

	var oldest_allowed_time := elapsed_time - follow_delay - 2.0

	while (
		not trail_times.is_empty()
		and trail_times[0] < oldest_allowed_time
	):
		trail_times.pop_front()
		trail_positions.pop_front()



func follow_delayed_position(delta: float) -> void:
	var target_time := elapsed_time - follow_delay

	if trail_times.is_empty() or target_time < trail_times[0]:
		velocity.x = 0.0
		velocity.z = 0.0
		return

	var target_position: Vector3 = trail_positions[0]

	for i in range(trail_times.size() - 1):
		if target_time <= trail_times[i + 1]:
			var duration := trail_times[i + 1] - trail_times[i]
			var weight := 0.0

			if duration > 0.0:
				weight = (target_time - trail_times[i]) / duration

			target_position = trail_positions[i].lerp(
				trail_positions[i + 1],
				weight
			)
			break

	if repath_timer <= 0.0:
		navigation_agent.target_position = target_position
		
		print(
			"Monster2 target: ", target_position,
			" | reachable: ", navigation_agent.is_target_reachable(),
			" | finished: ", navigation_agent.is_navigation_finished()
		)

		repath_timer = repath_interval

	if navigation_agent.is_navigation_finished():
		var distance_to_target := Vector2(
			global_position.x - target_position.x,
			global_position.z - target_position.z
		).length()

		if distance_to_target <= navigation_agent.target_desired_distance:
			velocity.x = 0.0
			velocity.z = 0.0
			return

	var next_position: Vector3 = navigation_agent.get_next_path_position()
	var direction: Vector3 = next_position - global_position
	direction.y = 0.0

	# Jika waypoint terlalu dekat, gunakan arah ke target akhir
	# agar Monster2 tidak terus berhenti pada waypoint yang sama.
	if direction.length_squared() < 0.01:
		direction = target_position - global_position
		direction.y = 0.0

	if direction.length_squared() < 0.01:
		velocity.x = 0.0
		velocity.z = 0.0
		return

	direction = direction.normalized()

	velocity.x = direction.x * follow_speed
	velocity.z = direction.z * follow_speed

	var target_angle := atan2(-direction.x, -direction.z)
	rotation.y = lerp_angle(
		rotation.y,
		target_angle,
		1.0 - exp(-rotation_speed * delta)
	)



func catch_player() -> void:
	if current_state == Monster2State.CAUGHT:
		return

	current_state = Monster2State.CAUGHT
	velocity = Vector3.ZERO

	print("Monster2: PLAYER CAUGHT")
