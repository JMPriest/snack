extends CanvasLayer

signal restart


func _on_result_button_pressed() -> void:
	restart.emit()
