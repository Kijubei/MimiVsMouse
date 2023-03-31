extends KinematicBody

signal mouseCaught

var playerInRange: KinematicBody = null

export var targetPath = NodePath()
export var speed = 10

onready var kiteAI = preload("res://Scenes/KiteAI.gd").new()

onready var agent: Navigation = $MausAgent
onready var targetNode = get_node(targetPath)

func _ready():
	kiteAI._ready()
	if targetPath != null:
		print("yes")
	#	agent.set_target_location(targetNode.)
		
#func _physics_process(delta):
#	if agent.is_navigation_finished():
#		return
	
#	var next: Vector3 = agent.get_next_location()
#	var velocity = (next - transform.origin).normalized() * speed * delta
#	velocity = velocity.move_toward((next - transform.origin).normalized() * speed * delta, 20)
#	move_and_collide(velocity)
#	Maus ist falsch rum (?)
#	look_at(next, Vector3.UP)

func _on_CatchArea_body_entered(_body):
	emit_signal("mouseCaught")

func _on_PlayerDetectionArea_body_entered(body):
	playerInRange = body
