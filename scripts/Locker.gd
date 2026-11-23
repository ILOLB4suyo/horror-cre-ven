
extends Interactable

enum LockerState {
	AVAILABLE,
	ENTERING,
	HIDDEN,
	EXITING
}



@export_group("Locker References")
@export var hide_position: Marker3D
@export var exit_position: Marker3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

@export var door_mesh: MeshInstance3D
@export_range(0.0, 1.0) var hidden_door_alpha: float = 0.5

var door_material: BaseMaterial3D = null

var current_state: LockerState = LockerState.AVAILABLE
var opening_for_interaction: bool = false

var door_is_open: bool = false
var door_transitioning: bool = false

func can_interact(player) -> bool:
	return current_state == LockerState.AVAILABLE and not door_transitioning


func get_interaction_text(player) -> String:
	if current_state != LockerState.AVAILABLE:
		return ""

	return "HIDE - HOLD F"


# Dipanggil saat Player mulai menahan F
func interaction_started(player) -> void:
	if current_state != LockerState.AVAILABLE:
		return

	if door_transitioning:
		return

	opening_for_interaction = true

	# Jika pintu sudah terbuka, tidak perlu memainkan Open lagi
	if not door_is_open:
		animation_player.speed_scale = 1.0
		animation_player.play("Open")


# Dipanggil saat Player melepas F sebelum progress penuh
func interaction_cancelled(player) -> void:
	if not opening_for_interaction:
		return

	opening_for_interaction = false

	# Jika pintu sudah terbuka sebelum interaksi,
	# biarkan pintu tetap terbuka
	if door_is_open:
		return

	door_transitioning = true

	await close_door_from_current_position()

	door_transitioning = false


func close_door_from_current_position() -> void:
	var current_position := animation_player.current_animation_position

	# Jika pintu sudah tertutup
	if current_position <= 0.001:
		door_is_open = false
		return

	# Putar animasi mundur dari akhir
	animation_player.play("Open", -1.0, -1.0, true)

	# Kembalikan ke posisi terakhir sebelum dibalik
	animation_player.seek(current_position, true)

	await animation_player.animation_finished

	animation_player.speed_scale = 1.0
	door_is_open = false


# Dipanggil saat progress interaksi mencapai 100%
func interact(player: Node) -> void:
	if current_state != LockerState.AVAILABLE:
		return

	if hide_position == null or exit_position == null:
		push_error("Locker: HidePosition atau ExitPosition belum diatur.")
		return

	if not player.has_method("enter_locker"):
		push_error("Locker: Player tidak memiliki fungsi enter_locker().")
		return

	current_state = LockerState.ENTERING
	opening_for_interaction = false
	door_transitioning = true

	player.enter_locker(self)

	await close_door_from_current_position()

	door_transitioning = false

	if current_state == LockerState.ENTERING:
		current_state = LockerState.HIDDEN

		set_door_transparency(hidden_door_alpha)

		player.show_locker_exit_prompt()


# Dipanggil saat Player menekan F ketika sedang bersembunyi
func request_exit(player: Node) -> void:
	if current_state != LockerState.HIDDEN:
		return

	current_state = LockerState.EXITING
	door_transitioning = true

	player.hide_locker_exit_prompt()

	# Buka pintu
	animation_player.speed_scale = 1.0
	animation_player.play("Open")

	await animation_player.animation_finished

	door_is_open = true
	door_transitioning = false

	player.exit_locker(self)

	set_door_transparency(1.0)

	current_state = LockerState.AVAILABLE


func setup_door_materials() -> void:
	if door_mesh == null:
		push_error("Locker: Door Mesh belum diatur.")
		return

	# Ambil material dari Geometry > Material Override
	var original_material = door_mesh.material_override

	if original_material == null:
		push_error("Locker: Material Override Door kosong.")
		return

	if not original_material is BaseMaterial3D:
		push_error("Locker: Material Door bukan BaseMaterial3D.")
		return

	# Duplikasi agar tidak mengubah material aset asli
	door_material = original_material.duplicate() as BaseMaterial3D

	door_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	# Pasang material baru ke Door
	door_mesh.material_override = door_material

	print("Door Material Override berhasil disiapkan.")


func set_door_transparency(alpha: float) -> void:
	if door_material == null:
		return

	var color := door_material.albedo_color
	color.a = alpha
	door_material.albedo_color = color

	print("Door Alpha sekarang: ", door_material.albedo_color.a)


func _ready() -> void:
	setup_door_materials()
	set_door_transparency(1.0)
