extends CharacterBody3D

##Variables
@export var spd = 5
@export var runSpd = 20
@export var jumpVel = 4.5

var grav = ProjectSettings.get_setting("physics/3d/default_gravity")
var velY = 0
var looksense = ProjectSettings.get_setting("player/look_sensitivity")
var contlooksense = ProjectSettings.get_setting("player/cont_look_sensitivity")
var running = false
const LerpVal = .1
var canJump = true
var Crouching = false
var aiming = false
var could_climb = true
var lClimping = false
var snap = 0
var time = 0
var touchingL = false

##ObjectCall
@onready var char = $Char
@onready var headcol = $Head
@onready var springpivot = $SpringArmPivot
@onready var springarm = $SpringArmPivot/SpringArm3D


##Checkingifthehightisappropriate
func can_climb():
	if could_climb:
		if !$Char/ChestRay.is_colliding():
			return false
		for ray in $Char/HeadRays.get_children():
			if ray.is_colliding():
				return false
		return true

##Climbing
func climb():
	velocity = Vector3.ZERO
	canJump = false
	
	var v_move_time = 0.4
	var h_move_time = 0.2
	
	if !Crouching:
		var v_mvmtn = global_transform.origin + Vector3(0,1.75,0)
		var v_twn = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		v_twn.tween_property(self, "global_transform:origin", v_mvmtn, v_move_time)
		
		await v_twn.finished
		
		var h_mvmtn = global_transform.origin + (-char.basis.z * 1)
		var h_twn = get_tree().create_tween().set_trans(Tween.TRANS_LINEAR)
		h_twn.tween_property(self, "global_transform:origin", h_mvmtn, h_move_time)
	canJump = true

##CapturingMouse 
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	if Input.is_action_just_pressed("run_input"):
		if  running:
			running = false
		else:
			running = true

##Checking if it is a ladder
	var static_body = $Char/ChestRay.get_collider()
	if static_body != null:
		var meta = static_body.get_meta("Ladder")
		if meta == true:
			touchingL = true

	if time > 0:
		time -= 1

##Movement Check
	var hVel = Input.get_vector("left_input","right_input","forward_input","backward_input")
	var direction = (transform.basis * Vector3(hVel.x,0,hVel.y)).normalized()
	direction = direction.rotated(Vector3.UP, springpivot.rotation.y)
	
##Move
	if !Crouching:
		if !lClimping:
			if !aiming:
				if running:
					if hVel:
						velocity.x = direction.x * runSpd
						velocity.z = direction.z * runSpd
						if is_on_floor():
							char.rotation.y = lerp_angle(char.rotation.y, atan2(-velocity.x, -velocity.z), LerpVal)
						else:
							char.rotation.y = lerp_angle(char.rotation.y, atan2(-velocity.x, -velocity.z), LerpVal /2)
					else:
						velocity.x = move_toward(velocity.x,0, runSpd)
						velocity.z = move_toward(velocity.z,0, runSpd)
				else:
					if hVel:
						velocity.x = direction.x * spd
						velocity.z = direction.z * spd
						if is_on_floor():
							char.rotation.y = lerp_angle(char.rotation.y, atan2(-velocity.x, -velocity.z), LerpVal)
						else:
							char.rotation.y = lerp_angle(char.rotation.y, atan2(-velocity.x, -velocity.z), LerpVal /2)
					else:
						velocity.x = move_toward(velocity.x,0, spd)
						velocity.z = move_toward(velocity.z,0, spd)
			elif aiming:
				if hVel:
					velocity.x = direction.x * (spd/2)
					velocity.z = direction.z * (spd/2)
				else:
					velocity.x = move_toward(velocity.x,0, spd)
					velocity.z = move_toward(velocity.z,0, spd)
				char.rotation.y = lerp_angle(springpivot.rotation.y, 0, LerpVal)
			could_climb = true
			canJump = true
			if Input.is_action_just_pressed("interact_input") and touchingL and $Char/ChestRay.is_colliding() and $Char/HeadRays/Right.is_colliding() and $Char/HeadRays/Left.is_colliding():
				lClimping = true
		else:
			var f_input = Input.get_action_strength("backward_input") - Input.get_action_strength("forward_input")
			if f_input:
				snap -= f_input/5
			else:
				snap = 0
			if Input.is_action_just_pressed("jump_input"):
				lClimping = false
			velocity.x = 0
			velocity.z = 0
			could_climb = true
			canJump = false
			if can_climb():
				lClimping = false
				climb()
			if f_input > 0 and is_on_floor():
				lClimping = false
		if time == 0:
			if Input.is_action_just_pressed("crouch_input") and is_on_floor():
				time = 5
				Crouching = true
				velY = -20
		##sets standing hight
		headcol.set("position",Vector3(0, 1.452, 0))
	else:
		##sets crouched hight
		headcol.set("position",Vector3(0, .6, 0))
		velY = -20
		if !aiming:
			if hVel:
				velocity.x = direction.x * (spd/2)
				velocity.z = direction.z * (spd/2)
				if is_on_floor():
					char.rotation.y = lerp_angle(char.rotation.y, atan2(-velocity.x, -velocity.z), LerpVal)
				else:
					char.rotation.y = lerp_angle(char.rotation.y, atan2(-velocity.x, -velocity.z), LerpVal /2)
			else:
				velocity.x = move_toward(velocity.x,0, spd/2)
				velocity.z = move_toward(velocity.z,0, spd/2)
		elif aiming:
			if hVel:
				velocity.x = direction.x * (spd/3)
				velocity.z = direction.z * (spd/3)
			else:
				velocity.x = move_toward(velocity.x,0, spd)
				velocity.z = move_toward(velocity.z,0, spd)
			char.rotation.y = lerp_angle(springpivot.rotation.y, 0, LerpVal)
		if time == 0:
			if Input.is_action_just_pressed("crouch_input") and !$Char/HeadCenterRay.is_colliding():
				time = 5
				Crouching = false

	##CollisionCheckForGravity
	if is_on_floor():
		velY = 0

	##jumpCheck
	if Input.is_action_just_pressed("jump_input") and canJump and is_on_floor() and !Crouching: 
		velY = jumpVel
	elif Input.is_action_just_pressed("jump_input") and can_climb() and !Crouching:
		climb()
	else:
		velY -= grav * delta  + .1
	if !lClimping:
		velocity.y = velY
	else:
		velocity.y = snap
	move_and_slide()
	
		##QuickQuit
	if Input.is_action_pressed("aim_input"):
		aiming = true
		springarm.spring_length = 2
	else:
		springarm.spring_length = 3
		aiming = false
	
	##QuickQuit
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
	pass

##Camera(MOUSE)
func _unhandled_input(event):
	if event is InputEventMouseMotion:
		springpivot.rotate_y(-event.relative.x * looksense)
		springarm.rotate_x(-event.relative.y * looksense)
		springarm.rotation.x = clamp(springarm.rotation.x, -PI/4, PI/4)

##Camera(JOYSTICK)
func _process(delta):
	var rotation_vector = Vector2.ZERO
	rotation_vector.x = Input.get_action_strength("joy_left") - Input.get_action_strength("joy_right")
	rotation_vector.y = Input.get_action_strength("joy_down") - Input.get_action_strength("joy_up")
	rotation_vector = rotation_vector.normalized()

	springpivot.rotate_y(rotation_vector.x * contlooksense)
	springarm.rotate_x(rotation_vector.y * contlooksense)
	springarm.rotation.x = clamp(springarm.rotation.x, -PI/4, PI/4)
	
