class_name Interactable
extends StaticBody3D


@export var interaction_hold_time: float = 1.0


func can_interact(_player) -> bool:
	return true


func get_interaction_text(_player) -> String:
	return "HOLD E"


func interact(_player) -> void:
	pass
