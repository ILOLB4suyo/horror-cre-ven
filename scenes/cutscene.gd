extends Control

@onready var video_player: VideoStreamPlayer = $VideoStreamPlayer
@onready var fade: ColorRect = $CanvasLayer/Fade

var transitioning = false

func _ready():
	video_player.finished.connect(_on_video_finished)
	video_player.play()

func _on_video_finished():
	if transitioning:
		return

	transitioning = true

	var tween = create_tween()
	tween.tween_property(fade, "color:a", 1.0, 1.5)

	await tween.finished

	get_tree().change_scene_to_file("res://scenes/Main.tscn")
