
extends CharacterBody3D

enum MonsterState {
	PATROL,
	CHASE,
	SEARCH,
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

@export_group("Navigation Recovery")
@export var repath_interval: float = 0.5
@export var stuck_check_interval: float = 1.0
@export var stuck_min_distance: float = 0.15

@export_group("Search")
@export var search_duration: float = 5.0
@export var search_arrival_distance: float = 1.0
@export var search_radius: float = 3.0

var search_timer: float = 0.0
var last_seen_player_position: Vector3 = Vector3.ZERO
var search_target_position: Vector3 = Vector3.ZERO

var repath_timer: float = 0.0
var stuck_timer: float = 0.0
var last_stuck_check_position: Vector3 = Vector3.ZERO


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

	last_stuck_check_position = global_position

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

		MonsterState.SEARCH:
			search_for_player(delta)

	move_and_slide()
	check_if_stuck(delta)



func update_state() -> void:
	if player == null or not is_instance_valid(player):
		return

	var distance_to_player := global_position.distance_to(
		player.global_position
	)

	var can_see_player := (
		distance_to_player <= detection_range
		and has_line_of_sight()
	)

	match current_state:
		MonsterState.PATROL:
			if can_see_player:
				current_state = MonsterState.CHASE
				last_seen_player_position = player.global_position
				repath_timer = 0.0
				navigation_agent.target_position = player.global_position
				print("Monster: PLAYER DETECTED - CHASING")

		MonsterState.CHASE:
			if distance_to_player <= catch_distance:
				catch_player()
				return

			if can_see_player:
				last_seen_player_position = player.global_position
			else:
				start_search()

		MonsterState.SEARCH:
			if can_see_player:
				current_state = MonsterState.CHASE
				last_seen_player_position = player.global_position
				repath_timer = 0.0
				navigation_agent.target_position = player.global_position
				print("Monster: PLAYER FOUND - CHASING")



func start_search() -> void:
	current_state = MonsterState.SEARCH
	search_timer = search_duration
	search_target_position = last_seen_player_position

	navigation_agent.target_position = search_target_position

	print("Monster: PLAYER LOST - SEARCHING LAST KNOWN POSITION")



func search_for_player(delta: float) -> void:
	var distance_to_player := global_position.distance_to(
		player.global_position
	)

	if (
		distance_to_player <= detection_range
		and has_line_of_sight()
	):
		current_state = MonsterState.CHASE
		last_seen_player_position = player.global_position
		repath_timer = 0.0
		navigation_agent.target_position = player.global_position
		print("Monster: PLAYER FOUND - CHASING")
		return

	search_timer -= delta

	var distance_to_search_target := Vector2(
		global_position.x - search_target_position.x,
		global_position.z - search_target_position.z
	).length()

	if distance_to_search_target <= search_arrival_distance:
		velocity.x = 0.0
		velocity.z = 0.0

		if search_timer <= 0.0:
			finish_search()
		return

	if navigation_agent.is_navigation_finished():
		if search_timer > 0.0:
			set_next_search_target()
		else:
			finish_search()
		return

	move_toward_target(patrol_speed, delta)



func set_next_search_target() -> void:
	var angle := randf() * TAU
	var radius := randf_range(1.0, search_radius)

	var offset := Vector3(
		cos(angle) * radius,
		0.0,
		sin(angle) * radius
	)

	search_target_position = last_seen_player_position + offset
	navigation_agent.target_position = search_target_position


func finish_search() -> void:
	current_state = MonsterState.PATROL
	search_timer = 0.0
	set_patrol_target()

	print("Monster: SEARCH COMPLETE - RETURNING TO PATROL")


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
	repath_timer -= delta

	if repath_timer <= 0.0:
		navigation_agent.target_position = player.global_position
		repath_timer = repath_interval

	move_toward_target(chase_speed, delta)


func move_toward_target(speed: float, delta: float) -> void:
	if navigation_agent.is_navigation_finished():
		velocity.x = 0.0
		velocity.z = 0.0
		return

	var next_position := navigation_agent.get_next_path_position()
	var direction := next_position - global_position
	direction.y = 0.0

	if direction.length_squared() < 0.0001:
		velocity.x = 0.0
		velocity.z = 0.0
		return

	direction = direction.normalized()

	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	var target_angle := atan2(-direction.x, -direction.z)
	rotation.y = lerp_angle(
		rotation.y,
		target_angle,
		1.0 - exp(-rotation_speed * delta)
	)


func check_if_stuck(delta: float) -> void:
	stuck_timer += delta

	if stuck_timer < stuck_check_interval:
		return

	stuck_timer = 0.0

	var distance_moved := global_position.distance_to(
		last_stuck_check_position
	)

	last_stuck_check_position = global_position

	if current_state == MonsterState.DEAD:
		return

	if distance_moved < stuck_min_distance:
		if current_state == MonsterState.CHASE and is_instance_valid(player):
			navigation_agent.target_position = player.global_position
			print("Monster: STUCK - REPATHING PLAYER")
		elif current_state == MonsterState.PATROL:
			set_patrol_target()
			print("Monster: STUCK - REPATHING PATROL")

func set_patrol_target() -> void:
	if patrol_points.is_empty():
		return

	if patrol_index >= patrol_points.size():
		patrol_index = 0

	var point := patrol_points[patrol_index]

	if is_instance_valid(point):
		navigation_agent.target_position = point.global_position



func has_line_of_sight() -> bool:
	if player == null or not is_instance_valid(player):
		return false

	var ray_start := global_position + Vector3.UP * 1.5
	var ray_end := player.global_position + Vector3.UP * 1.2

	var query := PhysicsRayQueryParameters3D.create(
		ray_start,
		ray_end
	)

	query.exclude = [get_rid()]

	var result := get_world_3d().direct_space_state.intersect_ray(query)

	# Tidak ada objek yang menghalangi pandangan.
	if result.is_empty():
		return true

	# Raycast mengenai player atau node anak milik player.
	var collider = result.get("collider")

	if collider == player:
		return true

	if collider is Node and player.is_ancestor_of(collider):
		return true

	return false


func catch_player() -> void:
	if current_state == MonsterState.DEAD:
		return

	current_state = MonsterState.DEAD
	velocity = Vector3.ZERO

	print("Monster: PLAYER CAUGHT")

	if player.has_method("die"):
		player.die()
