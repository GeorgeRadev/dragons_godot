extends KinematicBody

var rotate : Vector3 = Vector3.FORWARD
var followBody : KinematicBody = null

func _ready():
	$Squirrel/AnimationPlayer.get_animation("ArmatureAction").set_loop(true)
	$Squirrel/AnimationPlayer.play("ArmatureAction",-1, 1 + 0.2 * randf())


func _physics_process(delta):
	if followBody != null:
		var currentPos = transform.origin
		rotate = rotate.rotated(Vector3.UP, delta *  PI).normalized()
		var destinationPos = followBody.transform.origin + (2.5 * rotate)
		var direction = (destinationPos - currentPos)
		# move to destination
		transform.origin += delta * direction
		rotation.y += delta *  PI
	else:
		move_and_collide(Vector3.DOWN)
		rotation.y += delta * abs(randf()) *  2 * PI
	# if fall off - keep on zero
	if transform.origin.y < 0:
		transform.origin.y = 0


func follow(o: KinematicBody):
	followBody = o


func is_squirrel():
	pass


func set_final(body: KinematicBody):
	followBody = body


func _on_SquirrelArea_body_entered(body):
	if followBody == null and body.has_method("is_dragon"):
		followBody = body
		$Pick.play()
