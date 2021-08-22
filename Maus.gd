extends KinematicBody

signal mouseCaught

func _on_CatchArea_body_entered(_body):
	emit_signal("mouseCaught")
