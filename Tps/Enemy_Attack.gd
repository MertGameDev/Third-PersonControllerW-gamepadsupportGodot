extends Area3D

var damage = 30
var timer = 10
# Called when the node enters the scene tree for the first time.
func _ready():
	body_entered.connect(on_body_entered)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	timer -= 1
	if timer == 0:
		queue_free()
	pass

func on_body_entered(body) -> void:
	if body is Enemy: return
	if body is Player:
		var player: Player = body as Player
		player.applyDamage(damage)
	queue_free()
