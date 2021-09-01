extends KinematicBody

signal mouseCaught

var player: KinematicBody = null

onready var kiteAI = preload("res://Scenes/KiteAI.gd").new()

func _ready():
	kiteAI._ready()

func _process(delta):
	if player:
		print("x " + str(player.global_transform.origin.x))
		print("y " + str(player.global_transform.origin.y))
		
		

func _on_CatchArea_body_entered(_body):
	emit_signal("mouseCaught")

func _on_PlayerDetectionArea_body_entered(body):
	player = body
