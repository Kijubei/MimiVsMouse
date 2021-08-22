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
const hLookSensibility = 1.0
const vLookSensibility = 1.0

onready var cam = $CamBase
onready var energyBar = $EnergyBar
onready var restTimer = $RestTimer

var state = walk
var velocity = Vector3.ZERO
var isPouncing = false
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
	var inputVector = applyInput()
	
	if inputVector != Vector3.ZERO:
		velocity = velocity.move_toward(inputVector * walkSpeed, acceleration)
	else:
		velocity = velocity.move_toward(Vector3.ZERO, friction)

	moveByVelocity()
		
	if grounded and Input.is_action_pressed("sprint") and fitForSprint():
		state = sprint
	if grounded and Input.is_action_pressed("pounce") and fitForPounce():
		state = pounce
	if grounded and Input.is_action_pressed("jump") and fitForJump():
		state = jump
		
	if energyBar.value < energyBar.max_value and !exhausted:
		energyBar.value += energyBar.step

########## SPRINT ##########

func fitForSprint() -> bool:
	return energyBar.value > 5

func sprintState(_delta):
	var inputVector = applyInput()
	
	if inputVector != Vector3.ZERO:
		velocity = velocity.move_toward(inputVector * sprintSpeed, acceleration)
	else:
		velocity = velocity.move_toward(Vector3.ZERO, friction)

	moveByVelocity()
		
	if grounded and Input.is_action_just_released("sprint"):
		state = walk
	if grounded and Input.is_action_pressed("pounce") and fitForPounce() :
		state = pounce
	if grounded and Input.is_action_pressed("jump") and fitForJump():
		state = jump
		
	if energyBar.value > energyBar.min_value:
		energyBar.value -= energyBar.step
	else:
		exhausted = true
		rest()
		state = walk

########## POUNCE ##########

func fitForPounce() -> bool:
	return (energyBar.value - energyBar.step*200) > energyBar.min_value

func pounceState(_delta):
	if !isPouncing:
		applyPounce()
	
	moveByVelocity()
	
	# needed somehow ...
	grounded = is_on_floor()
	
	if grounded:
		state = walk
		isPouncing = false
		

func applyPounce():
	isPouncing = true
	velocity *= pounceSpeedMultiplier
	velocity.y += pounceJumpForce
	velocity.z = clamp(velocity.z, -maxSpeed, maxSpeed)
	velocity.x = clamp(velocity.x, -maxSpeed, maxSpeed)
	velocity = move_and_slide(velocity, Vector3(0,1,0))
	energyBar.value -= energyBar.step*200
	return

########## JUMP ##########

func fitForJump() -> bool:
	return (energyBar.value - energyBar.step*200) > energyBar.min_value

func jumpState(_delta):
	if grounded:
		velocity.y += jumpForce
		energyBar.value -= energyBar.step*200
	
	moveByVelocity()
	
	# needed somehow ...
	grounded = is_on_floor()
	
	if grounded:
		state = walk

########## HELPER FUNC ##########

func applyInput() -> Vector3:
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
	inputVector = inputVector.rotated(Vector3(0, 1, 0), rotation.y)
	return inputVector

func moveByVelocity():
	velocity.y -= gravity
	velocity = move_and_slide(velocity, Vector3(0,1,0))

func rest():
	if exhausted:
		energyBar.modulate = Color(1,0,0,1)
		restTimer.start()

func _on_RestTimer_timeout():
	if exhausted:
		energyBar.modulate = Color(1,1,1,1)
		exhausted = false

func _on_Maus_mouseCaught():
	disabled = true
