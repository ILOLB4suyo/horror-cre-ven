extends CharacterBody3D

@export var walk_speed: float = 3.0
@export var run_speed: float = 5.0
@export var sneak_speed: float = 1.5


@export var max_stamina: float = 100.0
#@export var stamina_drain: float = 40.0
#@export var stamina_regen_idle: float = 15.0
#@export var stamina_regen_walk: float = 5.0

@export var stamina_drain: float = 10.0
@export var stamina_regen_idle: float = 55.0
@export var stamina_regen_walk: float = 55.0

@export var walk_bob_frequency: float = 8.0
@export var walk_bob_amplitude: float = 0.025

@export var run_bob_frequency: float = 12.0
@export var run_bob_amplitude: float = 0.045

@export var sneak_bob_frequency: float = 6.0
@export var sneak_bob_amplitude: float = 0.012


@export var mouse_sensitivity: float = 0.002

@export var peek_angle_degrees: float = 120.0
@export var peek_speed: float = 8.0

@export var interaction_distance: float = 3.0


var interaction_target: Interactable = null
var interaction_progress: float = 0.0
var is_reading: bool = false

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var hud = $"../HUD"

const GRAVITY: float = 9.8

var look_x: float = 0.0

var peek_direction: int = 0




enum MovementState{
	
	IDLE,
	WALKING,
	RUNNING,
	SNEAKING
	
}

var movement_state : MovementState = MovementState.IDLE

var stamina: float = max_stamina

var owned_items: Array[String] = []

var bob_time: float = 0.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func add_item(item_id: String) -> void:
	if not owned_items.has(item_id):
		owned_items.append(item_id)

func has_item(item_id: String) -> bool:
	return owned_items.has(item_id)

func _unhandled_input(event: InputEvent) -> void:
	
	if event.is_action_pressed("ui_cancel"):

		if is_reading:
			close_document()
			return

		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return


	if is_reading:
		return
	
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)

		look_x -= event.relative.y * mouse_sensitivity
		look_x = clamp(
			look_x,
			deg_to_rad(-89.0),
			deg_to_rad(89.0)
		)

		head.rotation.x = look_x





	if event.is_action_pressed("peek_left"):
		if peek_direction == 0:
			peek_direction = -1

	elif event.is_action_released("peek_left"):
		if peek_direction == -1:
			peek_direction = 0



	if event.is_action_pressed("peek_right"):
		if not has_interaction_target():
			if peek_direction == 0:
				peek_direction = 1

	elif event.is_action_released("peek_right"):
		if peek_direction == 1:
			peek_direction = 0


func has_interaction_target() -> bool:
	return get_interaction_target() != null


func _physics_process(delta: float) -> void:

	if is_reading:
		velocity = Vector3.ZERO
		return


	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0





	var input_dir := Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_backward"
	)


	var direction := (
		transform.basis * Vector3(
			input_dir.x, 
			0.0, 
			input_dir.y
		)
	).normalized()
	
	var current_speed := 0.0
	
	if direction:
		
		if Input.is_action_pressed("sneak"):
			movement_state = MovementState.SNEAKING
			current_speed = sneak_speed
		
		elif Input.is_action_pressed("run") and stamina > 0.0:
			movement_state = MovementState.RUNNING
			current_speed = run_speed
		
		else:
			movement_state = MovementState.WALKING
			current_speed = walk_speed
		
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	
	else:
		
		movement_state = MovementState.IDLE
		
		velocity.x = move_toward(
			velocity.x,
			0.0,
			walk_speed
		)
		
		velocity.z = move_toward(
			velocity.z,
			0.0,
			walk_speed
		)
		
	
	
	# Camera Bob
	var movement_amount := Vector2(
		velocity.x,
		velocity.z
	).length()

	update_camera_bob(delta, movement_amount)
	
	# Interaction
	var new_target := get_interaction_target()

	if new_target != interaction_target:
		interaction_target = new_target
		interaction_progress = 0.0
		hud.set_interaction_progress(0.0)

		if interaction_target != null:
			peek_direction = 0
		else:
			hud.hide_interaction_prompt()


	if interaction_target != null:
		var interaction_text := interaction_target.get_interaction_text(self)

		if interaction_text.is_empty():
			hud.hide_interaction_prompt()
		else:
			hud.show_interaction_prompt(interaction_text)


	update_interaction(delta)
	

	
	# stamina
	match movement_state:

		MovementState.RUNNING:
			stamina -= stamina_drain * delta

		MovementState.IDLE:
			stamina += stamina_regen_idle * delta

		MovementState.WALKING:
			stamina += stamina_regen_walk * delta

		MovementState.SNEAKING:
			pass


	stamina = clamp(
		stamina,
		0.0,
		max_stamina
	)
	
	print("State: ", MovementState.keys()[movement_state], " | Stamina: ", stamina)


	var peek_target := 0.0

	if peek_direction == -1:
		peek_target = deg_to_rad(peek_angle_degrees)

	elif peek_direction == 1:
		peek_target = deg_to_rad(-peek_angle_degrees)

	var peek_weight := 1.0 - exp(-peek_speed * delta)

	head.rotation.y = lerp_angle(
		head.rotation.y,
		peek_target,
		peek_weight
	)


	move_and_slide()





func update_camera_bob(delta: float, movement_amount: float) -> void:
	if movement_amount <= 0.0:
		bob_time = 0.0

		camera.position = camera.position.lerp(
			Vector3.ZERO,
			1.0 - exp(-10.0 * delta)
		)

		camera.rotation.z = lerp(
			camera.rotation.z,
			0.0,
			1.0 - exp(-10.0 * delta)
		)

		return


	var bob_frequency := 0.0
	var bob_amplitude := 0.0


	match movement_state:

		MovementState.WALKING:
			bob_frequency = walk_bob_frequency
			bob_amplitude = walk_bob_amplitude

		MovementState.RUNNING:
			bob_frequency = run_bob_frequency
			bob_amplitude = run_bob_amplitude

		MovementState.SNEAKING:
			bob_frequency = sneak_bob_frequency
			bob_amplitude = sneak_bob_amplitude

		MovementState.IDLE:
			return


	bob_time += delta * bob_frequency


	var bob_y := sin(bob_time) * bob_amplitude
	var bob_x := cos(bob_time * 0.5) * bob_amplitude * 0.5


	var target_position := Vector3(
		bob_x,
		bob_y,
		0.0
	)


	camera.position = camera.position.lerp(
		target_position,
		1.0 - exp(-12.0 * delta)
	)


	var target_roll := -bob_x * 0.5

	camera.rotation.z = lerp(
		camera.rotation.z,
		target_roll,
		1.0 - exp(-12.0 * delta)
	)



func get_interaction_target() -> Interactable:
	var space_state := get_world_3d().direct_space_state

	var from := camera.global_position
	var to := from + -camera.global_transform.basis.z * interaction_distance

	var query := PhysicsRayQueryParameters3D.create(
		from,
		to
	)

	query.exclude = [self]

	var result := space_state.intersect_ray(query)

	if result.is_empty():
		return null

	var collider = result["collider"]

	if collider is Interactable:
		return collider

	return null




func update_interaction(delta: float) -> void:
	if interaction_target == null:
		return

	if not interaction_target.can_interact(self):
		interaction_progress = 0.0
		hud.set_interaction_progress(0.0)
		return

	if Input.is_action_pressed("interact"):
		interaction_progress += delta / interaction_target.interaction_hold_time

		interaction_progress = clamp(
			interaction_progress,
			0.0,
			1.0
		)

		hud.set_interaction_progress(interaction_progress)

		if interaction_progress >= 1.0:
			interaction_target.interact(self)

			interaction_target = null
			interaction_progress = 0.0

			hud.hide_interaction_prompt()

	else:
		interaction_progress = 0.0
		hud.set_interaction_progress(0.0)


func open_document(title: String, content: String) -> void:
	is_reading = true

	velocity = Vector3.ZERO
	peek_direction = 0

	hud.hide_interaction_prompt()
	hud.show_document(title, content)

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close_document() -> void:
	is_reading = false

	hud.hide_document()

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
