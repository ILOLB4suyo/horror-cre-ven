
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

var current_state: LockerState = LockerState.AVAILABLE


func can_interact(player) -> bool:
	return current_state == LockerState.AVAILABLE


func get_interaction_text(player) -> String:
	if current_state != LockerState.AVAILABLE:
		return ""

	return "HIDE - HOLD F"



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
	player.enter_locker(self)

	animation_player.play("Close")
	await animation_player.animation_finished

	if current_state == LockerState.ENTERING:
		current_state = LockerState.HIDDEN
		player.show_locker_exit_prompt()



func request_exit(player: Node) -> void:
	if current_state != LockerState.HIDDEN:
		return

	current_state = LockerState.EXITING

	player.hide_locker_exit_prompt()

	animation_player.play("Open")
	await animation_player.animation_finished

	player.exit_locker(self)
	current_state = LockerState.AVAILABLE
