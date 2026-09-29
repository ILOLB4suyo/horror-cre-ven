extends CharacterBody3D

@export var walk_speed: float = 3.0
@export var run_speed: float = 5.0
@export var sneak_speed: float = 1.5


@export var max_stamina: float = 100.0
@export var stamina_drain: float = 40.0
@export var stamina_regen_idle: float = 15.0
@export var stamina_regen_walk: float = 5.0


@export var mouse_sensitivity: float = 0.002

@export var peek_angle_degrees: float = 120.0
@export var peek_speed: float = 8.0

@onready var head: Node3D = $Head

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

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)

		look_x -= event.relative.y * mouse_sensitivity
		look_x = clamp(
			look_x,
			deg_to_rad(-89.0),
			deg_to_rad(89.0)
		)

		head.rotation.x = look_x

	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE



	if event.is_action_pressed("peek_left"):
		if peek_direction == 0:
			peek_direction = -1

	elif event.is_action_released("peek_left"):
		if peek_direction == -1:
			peek_direction = 0



	if event.is_action_pressed("peek_right"):
		if peek_direction == 0:
			peek_direction = 1

	elif event.is_action_released("peek_right"):
		if peek_direction == 1:
			peek_direction = 0


func _physics_process(delta: float) -> void:

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
