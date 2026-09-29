extends CanvasLayer

@onready var player = $"../Player"
@onready var stamina_bar: ProgressBar = $StaminaUI/StaminaBar


func _process(_delta: float) -> void:
	stamina_bar.max_value = player.max_stamina
	stamina_bar.value = player.stamina
