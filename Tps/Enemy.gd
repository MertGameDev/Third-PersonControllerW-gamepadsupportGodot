extends CharacterBody3D

class_name Enemy

var states = 0
var grav = ProjectSettings.get_setting("physics/3d/default_gravity")
var hero
var velY = 0
var speed = 5
var time_since_move = 0.0
var move_direction = Vector3.ZERO
var navigation = null
var timer = 0
var attacktimer = 0
@export var enemy_attack: PackedScene
@export var turn_speed = 2.5
@onready var spawn_point = $CollisionShape3D/SpawnPoint
@onready var can_attack = $CollisionShape3D/attackcheck.is_colliding()

func _ready():
	hero = get_tree().get_nodes_in_group("Player")[0]

func _physics_process(delta):
	if attacktimer != 0:
		attacktimer -= 1
	var static_bodyStraight = $CollisionShape3D/playercheck/playercheckStraigt.get_collider()
	var static_bodyDown = $CollisionShape3D/playercheck/playercheckDown.get_collider()
	##States
	#Idle
	if states == 0:
		##PlayerChecking
		if static_bodyStraight != null or static_bodyDown != null:
			if (static_bodyStraight and static_bodyStraight.is_in_group("Player")) or (static_bodyDown and static_bodyDown.is_in_group("Player")):
				states = 1
				timer = 100
		##"RandomMovement"??I do not know how to make it
	#Chase
	if states == 1:
		##FaceTowardsPlayer
		$FaceDir.look_at(hero.global_transform.origin, Vector3.UP)
		rotate_y(deg_to_rad($FaceDir.rotation.y * turn_speed))
		##MoveTowardsPlayer
		$NavigationAgent3D.set_target_position(hero.global_transform.origin)
		var velocity = ($NavigationAgent3D.get_next_path_position() - transform.origin).normalized() * speed * delta
		move_and_collide(velocity)
		if (static_bodyStraight == null or !static_bodyStraight.is_in_group("Player")) or (static_bodyDown == null or !static_bodyDown.is_in_group("Player")):
			timer -= 1
		elif static_bodyStraight != null or static_bodyDown != null:
			if (static_bodyStraight and static_bodyStraight.is_in_group("Player")) or (static_bodyDown and static_bodyDown.is_in_group("Player")):
				timer = 100
		if timer == 0:
			states = 0
		var attack = $CollisionShape3D/attackcheck.get_collider()
		if attack != null:
			if attack and attack.is_in_group("Player"):
				if attacktimer == 0:
					states = 2
					attacktimer = 40
	#Attack
	if states == 2:
		shoot()
		states = 0
		velocity = Vector3.ZERO
	if is_on_floor():
		velY = 0
	else:
		velY = grav * delta
	velocity.y -= velY
	move_and_slide()
	
	pass

func shoot() -> void:
	print("bam")
	var inst = enemy_attack.instantiate()
	add_child(inst)
	inst.transform = spawn_point.transform

