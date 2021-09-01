extends KinematicBody

export var walkSpeed = 10
export var sprintSpeed = 30
export var acceleration = 5
export var jumpForce = 40
export var pounceJumpForce = 20
export var pounceSpeedMultiplier = 3
export var friction = 2

enum {
	walk,
	sprint
	pounce,
	jump
}

const maxSpeed = 100
const gravity = 0.98
const terminalVelocity = -25
const hLookSensibility = 0.2
const vLookSensibility = 0.2

onready var cam = $CamBase
onready var energyBar = $EnergyBar
onready var restTimer = $RestTimer
onready var animationPlayer = $MimiAnimation/AnimationPlayer

var state = walk
var velocity = Vector3.ZERO
var grounded = false
var exhausted = false
var disabled = false

func _input(event):
	if event is InputEventMouseMotion and !disabled:
		cam.rotation_degrees.x -= event.relative.y * vLookSensibility
		cam.rotation_degrees.x = clamp(cam.rotation_degrees.x, -90, 90)
		rotation_degrees.y -= event.relative.x * hLookSensibility

func _physics_process(delta):
	if disabled:
		return
	grounded = is_on_floor()
	
	if grounded:
		velocity.y = 0
	
	match state:
		walk:
			walkState(delta)
		sprint:
			sprintState(delta)
		pounce:
			pounceState(delta)
		jump:
			jumpState(delta)
			

########## WALK ##########

func walkState(_delta):
	applyInput(walkSpeed)
	applyWalkAnimation()
	moveByVelocity()
	switchStateFromWalk()
	restoreEnergyForWalk()

func applyWalkAnimation():
	if !(jumpAnimation() and animationPlayer.is_playing()):
		if velocity.x != 0 or velocity.z != 0:
			animationPlayer.play("Cat_walk")
		else:
			animationPlayer.play("Cat_idle")

func switchStateFromWalk():
	if grounded and Input.is_action_pressed("sprint") and fitForSprint():
		state = sprint
	if grounded and Input.is_action_pressed("pounce") and fitForPounce():
		state = pounce
	if grounded and Input.is_action_pressed("jump") and fitForJump():
		state = jump

func restoreEnergyForWalk():
	if energyBar.value < energyBar.max_value and !exhausted:
		energyBar.value += energyBar.step

########## SPRINT ##########

func sprintState(_delta):
	applyInput(sprintSpeed)
	animationPlayer.play("Cat_run")
	moveByVelocity()
	switchStateFromSprint()
	consumeEnergyForSprint()


func switchStateFromSprint():
	if grounded and Input.is_action_just_released("sprint"):
		state = walk
	if grounded and Input.is_action_pressed("pounce") and fitForPounce() :
		state = pounce
	if grounded and Input.is_action_pressed("jump") and fitForJump():
		state = jump

func consumeEnergyForSprint():
	if energyBar.value > energyBar.min_value:
		energyBar.value -= energyBar.step
	else:
		exhausted = true
		rest()
		state = walk

func fitForSprint() -> bool:
	return energyBar.value > 5

########## POUNCE ##########

func pounceState(_delta):
	applyPounce()
	holdJumpAnimation()
	moveByVelocity()
	stopStateOnGround()

func applyPounce():
	if grounded:
		animationPlayer.play("Cat_jump")
		velocity *= pounceSpeedMultiplier
		velocity.y += pounceJumpForce
		velocity.z = clamp(velocity.z, -maxSpeed, maxSpeed)
		velocity.x = clamp(velocity.x, -maxSpeed, maxSpeed)
		velocity = move_and_slide(velocity, Vector3(0,1,0))
		energyBar.value -= energyBar.step*200
		return

func fitForPounce() -> bool:
	return (energyBar.value - energyBar.step*200) > energyBar.min_value

########## JUMP ##########

func jumpState(_delta):
	applyJump()
	holdJumpAnimation()
	moveByVelocity()
	stopStateOnGround()

func applyJump():
	if grounded:
		velocity.y += jumpForce
		energyBar.value -= energyBar.step*200
		animationPlayer.play("Cat_jump")

func fitForJump() -> bool:
	return (energyBar.value - energyBar.step*200) > energyBar.min_value

########## HELPER FUNC ##########

func input() -> Vector3:
	var inputVector = Vector3.ZERO
	if Input.is_action_pressed("move_forward"):
		inputVector.z -= 1
	if Input.is_action_pressed("move_backward"):
		inputVector.z += 1
	if Input.is_action_pressed("move_left"):
		inputVector.x -= 1
	if Input.is_action_pressed("move_right"):
		inputVector.x += 1
	inputVector = inputVector.normalized()
	inputVector.y = velocity.y
	inputVector = inputVector.rotated(Vector3(0, 1, 0), rotation.y)
	
	return inputVector

func applyInput(speedMultiplier):
	var inputVector = input()
	if inputVector != Vector3.ZERO:
		velocity = velocity.move_toward(inputVector * speedMultiplier, acceleration)
	else:
		velocity = velocity.move_toward(Vector3(0,-1,0), friction)

func moveByVelocity():
	#bug: bei walk state ist gravity nicht richtig
	velocity.y -= gravity
	velocity.y = clamp(velocity.y, terminalVelocity, 1000)
	velocity = move_and_slide(velocity, Vector3.UP)

func stopStateOnGround():
	# needed somehow ...
	grounded = is_on_floor()
	
	if grounded:
		animationPlayer.play()
		state = walk

func holdJumpAnimation():
	if animationPlayer.current_animation_position > 0.4:
		animationPlayer.stop(false)

func rest():
	if exhausted:
		energyBar.modulate = Color(1,0,0,1)
		restTimer.start()

func jumpAnimation() -> bool:
	return animationPlayer.current_animation == "Cat_jump"

func _on_RestTimer_timeout():
	if exhausted:
		energyBar.modulate = Color(1,1,1,1)
		exhausted = false

func _on_Maus_mouseCaught():
	disabled = true
