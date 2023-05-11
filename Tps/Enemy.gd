extends CharacterBody3D

class_name Enemy
var states = 0
var grav = ProjectSettings.get_setting("physics/3d/default_gravity")
var hero
var velY = 0
var speed = 2
var time_since_move = 0.0
var move_direction = Vector3.ZERO
var navigation = null
var timer = 0
var attacktimer = 0
var static_bodyStraight = null
var lerpVal = 0.005
var Hp = 30
@export var enemy_attack: PackedScene
@export var turn_speed = 5
@onready var spawn_point = $CollisionShape3D/SpawnPoint
@onready var can_attack = $CollisionShape3D/attackcheck.is_colliding()
@onready var NavAgent = $NavigationAgent3D

func _ready():
	hero = get_tree().get_nodes_in_group("Player")[0]

func _physics_process(delta):
	var LastPosition = $CollisionShape3D/LastPoint.global_transform.origin
	if attacktimer != 0:
		attacktimer -= 1
	##States
	#Idle
	if states == 0:
		##PlayerChecking
		if static_bodyStraight != null:
				states = 1
				timer = 500
		velocity = Vector3.ZERO
		##"RandomMovement"??I do not know how to make it
	#Chase
	if states == 1:
		##FaceTowardsPlayer
		$FaceDir.look_at(hero.global_transform.origin, Vector3.UP)
		rotate_y(deg_to_rad($FaceDir.rotation.y * turn_speed))
		
		##MoveTowardsPlayer
		var currentLocation = global_transform.origin
		var NextPath = hero.global_transform.origin
		var NewVelocity = (NextPath - currentLocation).normalized() * speed
		NavAgent.set_velocity(NewVelocity)
		
		if is_on_floor():
			velY = 0
		else:
			velY = grav * delta
		velocity.y -= velY
		if static_bodyStraight == null:
			timer -= 1
		elif static_bodyStraight != null:
				timer += 1
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
	##VisionCone
	var overlaps = $CollisionShape3D/playercheck/VisionCone.get_overlapping_bodies()
	if overlaps.size()> 0:
		for overlap in overlaps:
			if overlap.name == "Player":
				var playerposition = overlap.global_transform.origin
				$CollisionShape3D/playercheck/playercheckStraigt.look_at(playerposition, Vector3.UP)
				if $CollisionShape3D/playercheck/playercheckStraigt.is_colliding():
					var colider = $CollisionShape3D/playercheck/playercheckStraigt.get_collider()
					if colider.is_in_group("Player"):
						static_bodyStraight = 1
					else:
						static_bodyStraight = null
	
	if Hp <= 0: queue_free()
	
	pass

func shoot() -> void:
	print("bam")
	var inst = enemy_attack.instantiate()
	add_child(inst)
	inst.transform = spawn_point.transform

func update_target_location(target_location):
	NavAgent.set_target_location(target_location)

func _on_navigation_agent_3d_velocity_computed(safe_velocity):
	velocity = velocity.move_toward(safe_velocity, .25)
	move_and_slide()

func applyDamage(damage) -> void:
	Hp -= damage


