extends CharacterBody3D

@export var walk_speed: float = 3.0
@export var mouse_sensitivity: float = 0.002

@export var peek_angle_degrees: float = 120.0
@export var peek_speed: float = 8.0

@onready var head: Node3D = $Head

const GRAVITY: float = 9.8

var look_x: float = 0.0

var peek_direction: int = 0


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
		transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)
	).normalized()

	if direction:
		velocity.x = direction.x * walk_speed
		velocity.z = direction.z * walk_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, walk_speed)
		velocity.z = move_toward(velocity.z, 0.0, walk_speed)



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
